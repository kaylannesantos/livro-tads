#!/usr/bin/env bash

# Publica o commit local em UM projeto existente do Overleaf Community Edition.
# Não há Git Bridge na Community Edition, portanto isto não tenta imitar um
# merge Git. Antes de qualquer escrita, baixa o ZIP atual do projeto e aborta
# se um arquivo que este script gerencia mudou no Overleaf desde o último envio.

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DEFAULT_OVERLEAF_URL="http://127.0.0.1"

usage() {
  cat <<'EOF'
Uso: scripts/sync-overleaf.sh <id-do-projeto>

Publica os arquivos versionados do commit HEAD no projeto informado,
preservando o mesmo ID do Overleaf. A árvore de trabalho deve estar limpa:
alterações não commitadas nunca são publicadas. Arquivos não versionados e
ignorados não são enviados.

Na primeira execução, o projeto deve estar vazio. Nas seguintes, o script
baixa e confere o projeto remoto antes de escrever. Se houver uma alteração ou
remoção remota em arquivo já gerenciado, ele aborta sem alterar nenhum lado;
resolva a divergência manualmente antes de tentar de novo. Arquivos criados só
no Overleaf são preservados, mas um arquivo novo local com o mesmo caminho faz
o script abortar para evitar sobrescrita.

Variáveis de ambiente:
  OVERLEAF_URL         URL da instância (padrão: http://127.0.0.1)
  OVERLEAF_EMAIL       E-mail da conta no Overleaf (obrigatório)
  OVERLEAF_PASSWORD    Senha da conta. Se omitida, ela é solicitada sem eco.
  OVERLEAF_ROOT_FOLDER_ID
                      ID da pasta-raiz do projeto. Obrigatório somente na
                      primeira execução em cada cópia local do repositório.

Exemplo:
  OVERLEAF_URL=http://100.119.176.112 OVERLEAF_EMAIL=voce@exemplo.com OVERLEAF_ROOT_FOLDER_ID=0123456789abcdef01234567 scripts/sync-overleaf.sh ID_DO_PROJETO

O estado local da sincronização (IDs e hashes da última publicação) fica em
dist/ e é ignorado pelo Git. Uma execução interrompida pode deixar uma
publicação parcial, mas a execução seguinte também abortará se detectar uma
diferença remota inesperada.
O script não acessa Docker, MongoDB ou o host do Toolkit. Após a primeira
execução, o ID da pasta-raiz fica salvo no estado local em dist/.
EOF
}

fail() {
  echo "Erro: $*" >&2
  exit 1
}

extract_csrf_token() {
  perl -0777 -ne '
    if (/<input\b[^>]*\bname="_csrf"[^>]*\bvalue="([^"]+)"/) {
      print "$1\n";
    } elsif (/<meta\b[^>]*\bname="ol-csrfToken"[^>]*\bcontent="([^"]+)"/) {
      print "$1\n";
    }
  '
}

is_publishable_path() {
  case "$1" in
    .git*|.agents/*|.codex/*|dist/*|scripts/*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

file_hash() {
  sha256sum "$1" | awk '{print $1}'
}

require_clean_tree() {
  if [[ -n "$(git -C "$ROOT_DIR" status --porcelain --untracked-files=all)" ]]; then
    fail "há alterações locais não versionadas; faça commit, stash ou reverta-as antes de publicar"
  fi
}

# O estado começa com root<TAB>id-da-pasta-raiz; os demais registros usam
# tipo<TAB>id<TAB>caminho<TAB>sha256. Estados das versões anteriores não tinham
# hash e só são migrados se os conteúdos local e remoto forem idênticos.
load_state() {
  local type entity_id path hash
  [[ -f "$state_path" ]] || return 0

  while IFS=$'\t' read -r type entity_id path hash; do
    case "$type" in
      root)
        [[ "$entity_id" =~ ^[a-f0-9]{24}$ ]] || fail "estado de sincronização inválido: $state_path"
        if [[ -n "${root_folder_id:-}" && "$root_folder_id" != "$entity_id" ]]; then
          fail "OVERLEAF_ROOT_FOLDER_ID não corresponde ao estado local de $project_id"
        fi
        root_folder_id="$entity_id"
        ;;
      folder)
        [[ "$entity_id" =~ ^[a-f0-9]{24}$ && -n "$path" ]] || fail "estado de sincronização inválido: $state_path"
        folder_ids["$path"]="$entity_id"
        ;;
      doc|file)
        [[ "$entity_id" =~ ^[a-f0-9]{24}$ && -n "$path" ]] || fail "estado de sincronização inválido: $state_path"
        entity_ids["$path"]="$entity_id"
        entity_types["$path"]="$type"
        entity_hashes["$path"]="$hash"
        [[ -n "$hash" ]] || legacy_state=true
        ;;
    esac
  done <"$state_path"
}

# Persiste após cada alteração remota. Assim, uma interrupção nunca faz o
# próximo envio acreditar que uma entidade excluída ainda existe.
save_state() {
  local temporary_state path commit_hash
  temporary_state="$(mktemp "$ROOT_DIR/dist/.overleaf-state.XXXXXX")"
  [[ "$root_folder_id" =~ ^[a-f0-9]{24}$ ]] || fail "ID da pasta-raiz do Overleaf ausente ou inválido"
  printf 'root\t%s\n' "$root_folder_id" >>"$temporary_state"

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    printf 'folder\t%s\t%s\n' "${folder_ids[$path]}" "$path" >>"$temporary_state"
  done < <(printf '%s\n' "${!folder_ids[@]}" | LC_ALL=C sort)

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    printf '%s\t%s\t%s\t%s\n' "${entity_types[$path]}" "${entity_ids[$path]}" "$path" "${entity_hashes[$path]}" >>"$temporary_state"
  done < <(printf '%s\n' "${!entity_ids[@]}" | LC_ALL=C sort)

  commit_hash="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
  printf 'base_commit\t%s\n' "$commit_hash" >>"$temporary_state"
  mv "$temporary_state" "$state_path"
}

delete_tracked_entity() {
  local path="$1"
  local entity_id="${entity_ids[$path]}"
  local entity_type="${entity_types[$path]}"

  curl --fail --silent --show-error --request DELETE \
    --cookie "$cookie_jar" \
    --header "X-CSRF-TOKEN: $csrf_token" \
    "$overleaf_url/project/$project_id/$entity_type/$entity_id" >/dev/null
  unset 'entity_ids[$path]' 'entity_types[$path]' 'entity_hashes[$path]'
  save_state
}

verify_remote_baseline() {
  local path expected_hash remote_hash

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    expected_hash="${entity_hashes[$path]}"
    remote_hash="${remote_hashes[$path]:-}"
    [[ -n "$remote_hash" ]] || fail "o arquivo '$path' foi removido no Overleaf desde a última publicação; nenhuma alteração foi enviada"
    [[ "$remote_hash" == "$expected_hash" ]] || fail "o arquivo '$path' foi alterado no Overleaf desde a última publicação; nenhuma alteração foi enviada"
  done < <(printf '%s\n' "${!entity_ids[@]}" | LC_ALL=C sort)
}

migrate_legacy_state() {
  local path local_hash remote_hash

  [[ "$legacy_state" == true ]] || return 0
  echo "Estado de sincronização antigo detectado; conferindo o projeto remoto antes de migrar..."
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    [[ -n "${local_hashes[$path]+present}" ]] || fail "'$path' foi removido localmente, mas o estado anterior não permite confirmar que ele não mudou no Overleaf; resolva manualmente antes de publicar"
    local_hash="${local_hashes[$path]}"
    remote_hash="${remote_hashes[$path]:-}"
    [[ -n "$remote_hash" ]] || fail "'$path' não existe mais no Overleaf; resolva manualmente antes de publicar"
    [[ "$local_hash" == "$remote_hash" ]] || fail "'$path' difere entre o commit local e o Overleaf; resolva manualmente antes de publicar"
    entity_hashes["$path"]="$local_hash"
  done < <(printf '%s\n' "${!entity_ids[@]}" | LC_ALL=C sort)
  legacy_state=false
  save_state
  echo "Estado de sincronização migrado sem alterar o Overleaf."
}

ensure_folder() {
  local directory="$1"
  local current_path="" component parent_folder_id="$root_folder_id" response folder_id
  local -a path_components

  [[ "$directory" == "." ]] && return 0
  IFS='/' read -r -a path_components <<<"$directory"
  for component in "${path_components[@]}"; do
    current_path="${current_path:+$current_path/}$component"
    if [[ -z "${folder_ids[$current_path]+present}" ]]; then
      response="$(curl --fail --silent --show-error \
        --cookie "$cookie_jar" \
        --header "X-CSRF-TOKEN: $csrf_token" \
        --data-urlencode "name=$component" \
        --data-urlencode "parent_folder_id=$parent_folder_id" \
        "$overleaf_url/project/$project_id/folder")"
      folder_id="$(printf '%s' "$response" | sed -n 's/.*"_id":"\([a-f0-9]*\)".*/\1/p')"
      [[ "$folder_id" =~ ^[a-f0-9]{24}$ ]] || fail "a pasta '$current_path' não retornou um ID: $response"
      folder_ids["$current_path"]="$folder_id"
      save_state
    fi
    parent_folder_id="${folder_ids[$current_path]}"
  done
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
    usage
    exit 0
  fi

  local project_id="${1:-${OVERLEAF_PROJECT_ID:-}}"
  local overleaf_url="${OVERLEAF_URL:-$DEFAULT_OVERLEAF_URL}"
  local overleaf_email="${OVERLEAF_EMAIL:-}"
  local overleaf_password="${OVERLEAF_PASSWORD:-}"
  local state_path cookie_jar login_page dashboard csrf_token commit_hash relative_path response entity_id entity_type file root_doc_id
  local directory parent_folder_id root_folder_id="${OVERLEAF_ROOT_FOLDER_ID:-}" upload_url hash remote_zip remote_dir remote_file
  local legacy_state=false has_state=false remote_is_empty=true
  local -A folder_ids entity_ids entity_types entity_hashes local_files local_hashes remote_hashes

  [[ "$project_id" =~ ^[a-f0-9]{24}$ ]] || fail "informe um ID de projeto Overleaf válido (24 caracteres hexadecimais)"
  [[ -n "$overleaf_email" ]] || fail "defina OVERLEAF_EMAIL com a conta da instância local"
  overleaf_url="${overleaf_url%/}"
  command -v unzip >/dev/null 2>&1 || fail "o comando 'unzip' é necessário para conferir o snapshot do Overleaf"
  require_clean_tree

  if [[ -z "$overleaf_password" ]]; then
    read -r -s -p "Senha do Overleaf para $overleaf_email: " overleaf_password
    echo
  fi
  [[ -n "$overleaf_password" ]] || fail "a senha não pode ser vazia"

  mkdir -p "$ROOT_DIR/dist"
  state_path="$ROOT_DIR/dist/overleaf-project-$project_id.tsv"
  [[ -f "$state_path" ]] && has_state=true
  cookie_jar="$(mktemp /tmp/livro-tads-overleaf-cookie.XXXXXX)"
  remote_zip="$(mktemp /tmp/livro-tads-overleaf-project.XXXXXX.zip)"
  remote_dir="$(mktemp -d /tmp/livro-tads-overleaf-project.XXXXXX)"
  trap "rm -f '$cookie_jar' '$remote_zip'; rm -rf '$remote_dir'" EXIT

  login_page="$(curl --fail --silent --show-error --cookie "$cookie_jar" --cookie-jar "$cookie_jar" "$overleaf_url/login")"
  csrf_token="$(printf '%s' "$login_page" | extract_csrf_token)"
  [[ -n "$csrf_token" ]] || fail "não foi possível obter o token CSRF da página de login"

  curl --fail --silent --show-error --location \
    --cookie "$cookie_jar" --cookie-jar "$cookie_jar" \
    --data-urlencode "_csrf=$csrf_token" \
    --data-urlencode "email=$overleaf_email" \
    --data-urlencode "password=$overleaf_password" \
    "$overleaf_url/login" >/dev/null

  dashboard="$(curl --fail --silent --show-error --cookie "$cookie_jar" "$overleaf_url/project")"
  csrf_token="$(printf '%s' "$dashboard" | extract_csrf_token)"
  [[ -n "$csrf_token" ]] || fail "login recusado ou sessão inválida"

  # Sempre use o conteúdo do commit, e não a árvore de trabalho. A checagem de
  # árvore limpa acima garante que ambos coincidam.
  while IFS= read -r -d '' file; do
    relative_path="$file"
    if ! is_publishable_path "$relative_path"; then
      continue
    fi
    local_files["$relative_path"]="$ROOT_DIR/$relative_path"
    local_hashes["$relative_path"]="$(file_hash "$ROOT_DIR/$relative_path")"
  done < <(git -C "$ROOT_DIR" ls-tree -r -z --name-only HEAD)

  load_state
  [[ "$root_folder_id" =~ ^[a-f0-9]{24}$ ]] || fail "defina OVERLEAF_ROOT_FOLDER_ID com o ID da pasta-raiz do projeto para inicializar esta cópia local"

  # A rota é a mesma usada pela opção "Download as source (.zip)" da UI.
  # O ZIP permite verificar a versão remota antes de executar um DELETE ou upload.
  curl --fail --silent --show-error --location \
    --cookie "$cookie_jar" \
    --output "$remote_zip" \
    "$overleaf_url/project/$project_id/download/zip"
  unzip -qq "$remote_zip" -d "$remote_dir" || fail "não foi possível ler o ZIP baixado do Overleaf"
  while IFS= read -r -d '' remote_file; do
    relative_path="${remote_file#"$remote_dir"/}"
    remote_hashes["$relative_path"]="$(file_hash "$remote_file")"
    remote_is_empty=false
  done < <(find "$remote_dir" -type f -print0)

  # Sem um estado anterior não existe uma base comum para detectar conflitos.
  # Exigimos projeto vazio em vez de assumir que arquivos remotos podem ser
  # substituídos. Isso torna a inicialização tão segura quanto um primeiro push.
  if [[ "$has_state" == false && "$remote_is_empty" == false ]]; then
    fail "não há estado local para este projeto e o Overleaf não está vazio; não é seguro escolher qual versão prevalece"
  fi

  migrate_legacy_state
  verify_remote_baseline

  # Somente arquivos já gerenciados e confirmados contra o snapshot remoto podem
  # ser removidos. Arquivos que existem apenas no Overleaf são preservados.
  while IFS= read -r relative_path; do
    [[ -n "$relative_path" ]] || continue
    [[ -n "${local_files[$relative_path]+present}" ]] || delete_tracked_entity "$relative_path"
  done < <(printf '%s\n' "${!entity_ids[@]}" | LC_ALL=C sort)

  while IFS= read -r relative_path; do
    [[ -n "$relative_path" ]] || continue
    file="${local_files[$relative_path]}"
    hash="${local_hashes[$relative_path]}"

    if [[ -n "${entity_ids[$relative_path]+present}" && "${entity_hashes[$relative_path]}" == "$hash" ]]; then
      continue
    fi

    if [[ -z "${entity_ids[$relative_path]+present}" && -n "${remote_hashes[$relative_path]+present}" ]]; then
      fail "'$relative_path' já existe no Overleaf, mas não foi publicado por este estado local; nenhuma alteração foi enviada"
    fi

    # A API de upload não substitui um arquivo homônimo. Somente o item
    # alterado é removido antes de ser enviado de volta.
    if [[ -n "${entity_ids[$relative_path]+present}" ]]; then
      delete_tracked_entity "$relative_path"
    fi

    directory="${relative_path%/*}"
    [[ "$directory" == "$relative_path" ]] && directory="."
    ensure_folder "$directory"
    parent_folder_id="$root_folder_id"
    [[ "$directory" != "." ]] && parent_folder_id="${folder_ids[$directory]}"
    upload_url="$overleaf_url/project/$project_id/upload"
    upload_url="$upload_url?folder_id=$parent_folder_id"
    response="$(curl --fail --silent --show-error \
      --cookie "$cookie_jar" \
      --header "X-CSRF-TOKEN: $csrf_token" \
      --form "name=$(basename "$file")" \
      --form "qqfile=@$file" \
      "$upload_url")"

    entity_id="$(printf '%s' "$response" | sed -n 's/.*"entity_id":"\([a-f0-9]*\)".*/\1/p')"
    entity_type="$(printf '%s' "$response" | sed -n 's/.*"entity_type":"\([a-z]*\)".*/\1/p')"
    [[ "$entity_id" =~ ^[a-f0-9]{24}$ ]] || fail "o upload de '$relative_path' não retornou um ID: $response"
    [[ "$entity_type" == "doc" || "$entity_type" == "file" ]] || fail "tipo de entidade inválido para '$relative_path': $response"
    entity_ids["$relative_path"]="$entity_id"
    entity_types["$relative_path"]="$entity_type"
    entity_hashes["$relative_path"]="$hash"
    save_state
  done < <(printf '%s\n' "${!local_files[@]}" | LC_ALL=C sort)

  root_doc_id="${entity_ids[livro.tex]:-}"
  [[ "$root_doc_id" =~ ^[a-f0-9]{24}$ ]] || fail "livro.tex não foi enviado; não é possível definir o documento principal"
  curl --fail --silent --show-error \
    --cookie "$cookie_jar" \
    --header "X-CSRF-TOKEN: $csrf_token" \
    --data-urlencode "rootDocId=$root_doc_id" \
    "$overleaf_url/project/$project_id/settings" >/dev/null

  save_state
  commit_hash="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
  echo "Sincronização concluída no projeto: $overleaf_url/project/$project_id"
  echo "Commit publicado: $commit_hash"
}

main "$@"
