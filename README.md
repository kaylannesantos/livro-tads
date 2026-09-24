# livro-tads

## Compilação local

A compilação local usa Docker e a imagem completa do TeX Live. Isso mantém as
dependências do livro (incluindo `biber` e `biblatex-abnt`) fora do sistema
operacional e torna o resultado reproduzível entre máquinas.

Pré-requisito: Docker em execução e acessível ao usuário atual. Confirme com:

```bash
docker run --rm hello-world
```

Na primeira compilação a imagem do TeX Live será baixada. A partir da raiz
deste repositório, execute:

```bash
make pdf
```

O PDF estará em `build/livro.pdf`. Para manter a compilação ativa enquanto
edita os arquivos `.tex` e `.bib`, use `make watch` e encerre com `Ctrl+C`.
Para apagar apenas os arquivos gerados localmente, use `make clean`.

## Fonte do livro

O `make pdf` usa XeLaTeX e carrega diretamente a família **Arial Narrow**
versionada em `assets/fonts/`; não é necessário instalar a fonte no sistema ou
no container. Mantenha juntos os quatro arquivos (`regular`, `bold`, `italic`
e `bold italic`) para preservar a aparência do PDF. Antes de publicar o
repositório, confirme que a licença adquirida permite redistribuir esses
arquivos de fonte.

## Diagramação e modelo para autores

As decisões de identidade, cabeçalhos, tipografia e estrutura estão separadas
em [configuracoes/README.md](configuracoes/README.md). Autores devem receber e
copiar apenas [artigos/modelo_artigo/](artigos/modelo_artigo/): nele, os
comentários indicam exatamente quais metadados e seções precisam preencher,
sem permitir que alterem o layout global do livro.

Por padrão o projeto usa a imagem mais recente do TeX Live. Para testar ou
fixar uma versão sem editar os arquivos do projeto, informe a imagem no
comando:

```bash
make pdf TEXLIVE_IMAGE=ghcr.io/xu-cheng/texlive-full:20250701
```

Os diretórios `build/` e `dist/` não entram no Git. Portanto o fluxo diário é:
editar, conferir com `make pdf`, revisar `build/livro.pdf`, e então versionar
somente as alterações de fonte com `git add` e `git commit`.

## Sincronização com GitHub e Overleaf

O GitHub é a fonte oficial deste livro. A instância local do Overleaf Community
Edition serve para edição e prévia do PDF, mas não oferece sincronização Git
nativa. Use o script abaixo a partir da raiz do repositório:

```bash
scripts/sync-github.sh pull
```

O comando atualiza a branch local por *fast-forward* a partir de `origin/main`
e gera `dist/livro-tads-overleaf.zip`. Envie esse ZIP ao Overleaf e selecione
`livro.tex` como arquivo principal.

Outros comandos disponíveis:

```bash
# Publica commits locais no GitHub e recria o ZIP.
scripts/sync-github.sh push

# Apenas recria o ZIP do commit atual, sem acesso à rede.
scripts/sync-github.sh package
```

O script interrompe a operação caso existam arquivos modificados sem commit ou
se houver divergência de histórico, evitando sobrescrever trabalho local.

### Publicar um snapshot protegido no Overleaf

Depois de atualizar ou publicar um commit no GitHub, envie esse mesmo commit ao
seu projeto existente do Overleaf com:

```bash
OVERLEAF_URL=http://100.119.176.112 \
OVERLEAF_EMAIL=voce@exemplo.com \
OVERLEAF_ROOT_FOLDER_ID=ID_DA_PASTA_RAIZ \
scripts/sync-overleaf.sh ID_DO_PROJETO
```

Copie o ID da URL do projeto: em `http://100.119.176.112/project/ID_DO_PROJETO`,
ele é o trecho após `/project/`. O script solicita a senha sem exibi-la e sempre
publica apenas o `HEAD` do Git: exige uma árvore de trabalho limpa e nunca envia
alterações ainda sem commit.

Na primeira execução, use um projeto vazio. Nas demais, antes de qualquer
escrita, o script baixa o ZIP atual do Overleaf e compara os hashes de todos os
arquivos que ele já gerencia. Se um arquivo tiver sido alterado ou removido no
Overleaf, a execução falha sem apagar ou enviar nada. Arquivos existentes apenas
no Overleaf são preservados; se o Git tentar criar um arquivo no mesmo caminho,
o script também falha para que a decisão seja manual. Arquivos removidos do Git
só são removidos do Overleaf quando o conteúdo remoto ainda corresponde à última
publicação conhecida. O estado dessa relação é mantido em `dist/`, sem entrar no
Git.

O script pode ser executado de qualquer máquina que alcance o Overleaf: ele não
usa Docker nem MongoDB. Na primeira execução dessa cópia do repositório, defina
`OVERLEAF_ROOT_FOLDER_ID`; o valor é salvo no estado local para as próximas.
Esse ID pode ser obtido uma única vez no host do Toolkit com a consulta abaixo,
ou na mensagem `joinProject` da conexão Socket.IO nas ferramentas de
desenvolvedor do navegador (`project.rootFolder[0]._id`):

```bash
docker exec mongo mongosh --quiet --eval \
  "const p=db.projects.findOne({_id:ObjectId('ID_DO_PROJETO')},{rootFolder:1}); print(p.rootFolder[0]._id.toString())" \
  sharelatex
```

Esse é um *push* protegido, não um Git bidirecional: para trazer uma edição do
Overleaf ao repositório, baixe o ZIP, faça a comparação/merge local e crie o
commit antes de publicar de novo. Para `pull` e merge automáticos como Git, a
instância precisa do Git Bridge do Overleaf Server Pro.
