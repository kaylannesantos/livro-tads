# livro-tads

Projeto LaTeX para diagramar uma coletânea de artigos do curso de TADS do
Instituto Federal do Piauí (IFPI).

## Estado atual

O projeto já tem a estrutura editorial do livro, configurações separadas para a
equipe de diagramação e um modelo de artigo com metadados, referências, figuras
e texto de demonstração. No momento, `livro.tex` inclui somente
`artigos/modelo_artigo/`; essa pasta contém um artigo demonstrativo sobre jogos
digitais, imagens ilustrativas e dados fictícios. Ela demonstra o layout e não
deve ser publicada como artigo real.

Os dados de título, subtítulo e organização da capa e as páginas reservadas
para conteúdo editorial continuam como campos ou marcadores a preencher. A
marca IFPI usada no TCC está em `assets/marca-ifpi.pdf` e já aparece na capa,
folha de rosto e contracapa. Antes da edição final, substitua os campos e
integre os artigos aprovados.

## Estrutura do projeto

- `livro.tex`: documento principal; define a ordem das páginas e inclui os
  artigos.
- `configuracoes/`: fonte, margens, identidade, cabeçalhos, estrutura e sumário.
  Consulte [configuracoes/README.md](configuracoes/README.md) antes de alterar o
  layout.
- `artigos/modelo_artigo/`: modelo destinado aos autores, com instruções em
  `README.md` e imagens de exemplo em `imagens/`.
- `assets/fonts/`: arquivos Arial Narrow usados na compilação.
- `assets/marca-ifpi.pdf`: marca vetorial IFPI usada nas páginas institucionais.
- `scripts/`: ferramentas para empacotar o projeto para Overleaf e publicar um
  commit no projeto Overleaf existente.

## Compilação

A compilação local usa Docker e a imagem completa do TeX Live, que fornece
XeLaTeX, Biber e biblatex-abnt. Requer Docker em execução e acessível ao
usuário atual; pode-se conferir com:

~~~bash
docker run --rm hello-world
~~~

Execute os comandos abaixo na raiz do repositório:

~~~bash
make pdf      # compila o livro em build/livro.pdf
make modelo   # compila só o modelo em build/modelo/preview.pdf
make watch    # recompila livro.tex ao salvar arquivos TeX ou BibTeX
make clean    # limpa artefatos de compilação de livro.tex
~~~

Encerre `make watch` com `Ctrl+C`. `make image` baixa ou atualiza a imagem do
TeX Live. A imagem padrão usa a versão mais recente; para fixar outra versão sem
editar o projeto, informe-a no comando:

~~~bash
make pdf TEXLIVE_IMAGE=ghcr.io/xu-cheng/texlive-full:20250701
~~~

O XeLaTeX carrega Arial Narrow dos quatro arquivos versionados em
`assets/fonts/`; não é necessário instalar a família dentro do sistema ou do
container. Preserve esses arquivos e confirme que a licença permite distribuí-los
ao compartilhar o repositório.

## Fluxo dos artigos

Autores devem trabalhar numa cópia de `artigos/modelo_artigo/`. Substituam o
artigo demonstrativo sobre jogos e os dados fictícios em `metadados.tex`,
`artigo.tex` e `refs.bib`; mantenham em `refs.bib` apenas obras citadas e
coloquem as figuras em `imagens/`. As instruções e a sequência editorial estão em
[artigos/modelo_artigo/README.md](artigos/modelo_artigo/README.md).

As figuras devem ser citadas no texto e inseridas próximas à primeira menção.
Use `\inserirfigura` para obter legenda acima, centralização, referência por
rótulo e fonte abaixo, no fluxo adotado pelo template TCC/Monografia. Exemplo:

~~~tex
Como mostra a Figura~\ref{fig:arquitetura}, ...

\inserirfigura[0.7\textwidth]
  {fig:arquitetura}
  {Arquitetura proposta para o sistema}
  {imagens/arquitetura.jpg}
  {Elaboração própria (2026).}
~~~

As configurações do livro formatam as identificações como “Figura 1 – …” e
“Tabela 1 – …” em Arial Narrow 11, com fonte abaixo. Consulte
`artigos/modelo_artigo/imagens/README.md` e as diretivas editoriais para
formatos, resolução, identificação e fonte das imagens.

No estado atual, `livro.tex` registra explicitamente apenas o arquivo de
referências do modelo. Ao integrar artigos reais, registre também os arquivos
`refs.bib` no preâmbulo. Para manter a descoberta automática de todos os
arquivos dentro de `artigos/`, pode-se usar a forma glob abaixo, já usada na
prévia do modelo. Importe cada artigo dentro de uma seção de referências
independente:

~~~tex
\addbibresource[glob=true]{artigos/*/refs.bib}

% Dentro do documento, junto aos demais artigos:
\begin{refsection}
  \import{artigos/artigo_04/}{artigo.tex}
\end{refsection}
~~~

O artigo já chama `\referenciasartigo` ao final. A equipe integradora deve
retirar da inclusão final o modelo de demonstração depois de adicionar os
artigos reais.

## Sincronização com GitHub e Overleaf

O GitHub é a fonte versionada do livro. `scripts/sync-github.sh` atualiza ou
publica commits por fast-forward e pode gerar um ZIP com os arquivos do commit
atual para importar no Overleaf Community Edition. A árvore de trabalho precisa
estar limpa; divergências de histórico fazem o script parar para resolução
manual.

~~~bash
scripts/sync-github.sh pull    # traz origin/branch para a branch local e gera ZIP
scripts/sync-github.sh push    # envia commits locais e gera ZIP
scripts/sync-github.sh package # gera ZIP local, sem acessar a rede
~~~

O pacote fica em `dist/livro-tads-overleaf.zip`. Importe-o no Overleaf e
selecione `livro.tex` como documento principal. `TEXLIVE_IMAGE` afeta apenas a
compilação local pelo Makefile; escolha a versão do compilador disponível nas
configurações do projeto Overleaf.

Para publicar o commit `HEAD` diretamente num projeto existente do Overleaf,
use `scripts/sync-overleaf.sh`. Este é um envio protegido, não uma sincronização
Git bidirecional: edições feitas no Overleaf precisam ser baixadas, comparadas e
integradas localmente antes de novo envio.

~~~bash
OVERLEAF_URL=http://100.119.176.112 \
OVERLEAF_EMAIL=voce@exemplo.com \
OVERLEAF_ROOT_FOLDER_ID=ID_DA_PASTA_RAIZ \
scripts/sync-overleaf.sh ID_DO_PROJETO
~~~

O ID do projeto é o trecho após `/project/` na URL, com 24 caracteres
hexadecimais. O ID da pasta-raiz é necessário na primeira publicação dessa
cópia local do repositório; depois, fica registrado no estado local em `dist/`.
O script pede a senha sem exibi-la se `OVERLEAF_PASSWORD` não estiver definida.
Ele exige árvore de trabalho limpa e só publica arquivos versionados em `HEAD`.

Na primeira execução, o projeto Overleaf precisa estar vazio. Em publicações
seguintes, o script compara o conteúdo remoto gerenciado com os hashes da
publicação anterior e interrompe o envio se detectar edição ou remoção remota.
Arquivos criados apenas no Overleaf são preservados; se coincidirem com um novo
caminho local, o envio para para evitar sobrescrita. Um arquivo removido do Git
só é removido do Overleaf quando ainda corresponde à última versão publicada.
O script pode rodar em qualquer máquina que alcance a instância e não precisa
de Docker nem acesso ao MongoDB.

Se ainda precisar localizar o ID da pasta-raiz, a consulta abaixo pode ser
executada no host do Toolkit, substituindo o ID do projeto:

~~~bash
docker exec mongo mongosh --quiet --eval \
  "const p=db.projects.findOne({_id:ObjectId('ID_DO_PROJETO')},{rootFolder:1}); print(p.rootFolder[0]._id.toString())" \
  sharelatex
~~~

## Arquivos gerados

`build/` contém PDFs e artefatos de compilação; `dist/` contém o ZIP do Overleaf
e o estado local da sincronização protegida. Ambos são ignorados pelo Git e não
devem ser usados como cópia versionada do conteúdo-fonte.
