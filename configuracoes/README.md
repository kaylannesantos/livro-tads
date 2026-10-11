# Configurações para diagramação

Esta pasta concentra o layout do livro. A intenção é separar as decisões de
diagramação do conteúdo científico entregue pelos autores.

| Arquivo | Responsável | Altere aqui quando precisar… |
| --- | --- | --- |
| `base.tex` | Diagramação | fonte, margens, cores, títulos, citações longas e pacotes. |
| `identidade.tex` | Coordenação/diagramação | título do livro, autores da capa, local e marca IFPI. |
| `cabecalhos.tex` | Diagramação | paginação e estilos de página sem cabeçalho corrente. |
| `estrutura_livro.tex` | Diagramação | capa, folha de rosto, ficha catalográfica, páginas reservadas, contracapa e abertura de capítulo. |
| `sumario.tex` | Diagramação | nível de detalhe, pontilhado, paginação e linha de autores do sumário. |
| `modelo_artigo.tex` | Diagramação | como os dados em `metadados.tex` se tornam a abertura padronizada do artigo. |

## Fluxo seguro

1. A equipe editorial/diagramação configura `identidade.tex` e aprova a arte.
2. Os autores recebem uma cópia de `artigos/modelo_artigo/`, sem a pasta
   `configuracoes/`.
3. Cada autor preenche somente `metadados.tex`, `artigo.tex`, `refs.bib` e
   `imagens/` da própria cópia.
4. A pessoa que integra o livro adiciona o artigo em `livro.tex` dentro de um
   `refsection` e recompila com `make pdf`.

## Proteções editoriais

- Não introduza nome da revista Somma, ISSN, DOI, e-location ou datas de
  submissão/publicação sem metadados específicos desta edição.
- `\capitulocapa` deve permanecer a única abertura de capítulo: ela garante
  página ímpar, contador sequencial e entrada no sumário.
- A fonte Arial Narrow é carregada dos arquivos versionados em `assets/fonts`.
  O `Makefile` usa XeLaTeX; não troque para pdfLaTeX.
- Campos entre colchetes são pendências editoriais e não podem ser publicados.

## Estilo de página

O livro não usa cabeçalho corrente. O estilo padrão exibe apenas o número da
página no rodapé; use `\thispagestyle{empty}` quando também for necessário
ocultar a numeração, como em capa e contracapa.
