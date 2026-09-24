#!/usr/bin/env bash

# Mantém este repositório alinhado ao GitHub e cria um ZIP pronto para importar
# no Overleaf Community Edition. Não tenta gravar nas pastas internas do
# Overleaf, pois a Community Edition não oferece sincronização Git nativa.

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly OUTPUT_DIR="$ROOT_DIR/dist"
readonly ARCHIVE_PATH="$OUTPUT_DIR/livro-tads-overleaf.zip"

usage() {
  cat <<'EOF'
Uso: scripts/sync-github.sh <pull|push|package> [remoto] [branch]

Comandos:
  pull     Atualiza a branch local por fast-forward a partir do GitHub e gera o ZIP.
  push     Publica commits locais no GitHub, se o remoto não estiver à frente, e gera o ZIP.
  package  Gera o ZIP a partir do commit atual, sem acessar a rede.

Argumentos opcionais:
  remoto   Nome do remoto Git (padrão: origin).
  branch   Branch a sincronizar (padrão: branch atual).

O ZIP é criado em dist/livro-tads-overleaf.zip e contém apenas arquivos
versionados no commit atual. Envie esse arquivo ao criar ou atualizar o projeto
no Overleaf, definindo livro.tex como arquivo principal.
EOF
}

require_clean_tree() {
  if [[ -n "$(git -C "$ROOT_DIR" status --porcelain --untracked-files=all)" ]]; then
    echo "Erro: há alterações locais não versionadas. Faça commit, stash ou reverta-as antes de sincronizar." >&2
    exit 1
  fi
}

ensure_branch_exists() {
  local remote_ref="$1"
  if ! git -C "$ROOT_DIR" show-ref --verify --quiet "refs/remotes/$remote_ref"; then
    echo "Erro: a referência remota '$remote_ref' não existe." >&2
    exit 1
  fi
}

make_archive() {
  mkdir -p "$OUTPUT_DIR"
  git -C "$ROOT_DIR" archive --format=zip --output="$ARCHIVE_PATH" HEAD
  echo "Pacote pronto para o Overleaf: $ARCHIVE_PATH"
  echo "Commit incluído: $(git -C "$ROOT_DIR" rev-parse --short HEAD)"
}

main() {
  local action="${1:-}"
  local remote="${2:-origin}"
  local branch="${3:-$(git -C "$ROOT_DIR" branch --show-current)}"
  local remote_ref="$remote/$branch"

  case "$action" in
    pull)
      require_clean_tree
      git -C "$ROOT_DIR" fetch --prune "$remote"
      ensure_branch_exists "$remote_ref"

      if git -C "$ROOT_DIR" merge-base --is-ancestor HEAD "$remote_ref"; then
        git -C "$ROOT_DIR" merge --ff-only "$remote_ref"
      elif git -C "$ROOT_DIR" merge-base --is-ancestor "$remote_ref" HEAD; then
        echo "A branch local já está atualizada em relação a $remote_ref."
      else
        echo "Erro: a branch local divergiu de $remote_ref; resolva o merge manualmente." >&2
        exit 1
      fi
      make_archive
      ;;
    push)
      require_clean_tree
      git -C "$ROOT_DIR" fetch --prune "$remote"
      ensure_branch_exists "$remote_ref"

      if git -C "$ROOT_DIR" merge-base --is-ancestor "$remote_ref" HEAD; then
        git -C "$ROOT_DIR" push "$remote" "HEAD:$branch"
      else
        echo "Erro: $remote_ref contém commits ausentes localmente. Execute '$0 pull' primeiro." >&2
        exit 1
      fi
      make_archive
      ;;
    package)
      require_clean_tree
      make_archive
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
