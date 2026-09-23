# Configurações para diagramação

Esta pasta concentra o layout do livro. A intenção é separar as decisões de
diagramação do conteúdo científico entregue pelos autores.

| Arquivo | Responsável | Altere aqui quando precisar… |
| --- | --- | --- |
| `base.tex` | Diagramação | fonte, margens, cores, títulos, citações longas e pacotes. |
| `identidade.tex` | Coordenação/diagramação | título do livro, organizadores, textos institucionais e marca IFPI. |
| `cabecalhos.tex` | Diagramação | cabeçalho de páginas e mini-cabeçalho de abertura de artigos. |
| `estrutura_livro.tex` | Diagramação | capa, folha de rosto, fichas reservadas, contracapa e capa de capítulo. |
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
  página ímpar, contador sequencial, entrada no sumário, cabeçalho dinâmico e
  mini-cabeçalho com a mesma composição do modelo de referência.
- A fonte Arial Narrow é carregada dos arquivos versionados em `assets/fonts`.
  O `Makefile` usa XeLaTeX; não troque para pdfLaTeX.
- Campos entre colchetes são pendências editoriais e não podem ser publicados.

## Opções de cabeçalho por página

O padrão do livro é `fancy`, com cabeçalho e número da página. Quando uma
página específica não deve exibir cabeçalho, use `\thispagestyle{plain}` logo
após iniciá-la: o número no rodapé é preservado. Use `\thispagestyle{empty}`
somente quando também for necessário ocultar a numeração, como em capa e
contracapa.
