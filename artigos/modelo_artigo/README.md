# Modelo para autores — categoria Artigo

Copie esta pasta, renomeie-a, por exemplo, para `artigo_X`, e trabalhe apenas
nos arquivos da nova pasta. Não copie comandos de cabeçalho, fonte, margens ou
capa: eles vêm automaticamente das configurações do livro.

```bash
cp -R artigos/modelo_artigo artigos/artigo_04
```

## O que preencher

1. `metadados.tex`: título (até 25 palavras), autores, filiações, e-mails,
   ORCIDs, resumos e palavras-chave.
2. `artigo.tex`: texto científico nas seções já ordenadas.
3. `refs.bib`: somente obras citadas no texto; informe URLs quando disponíveis.
4. `imagens/`: imagens TIFF ou JPEG com pelo menos 300 DPI.

O modelo é exclusivo para a categoria **Artigo**. Revisões temáticas, relatos
de experiência e notas têm estruturas diferentes nas diretrizes.

O texto atual é um *lorem ipsum* de demonstração, com dados de autoria
fictícios e duas imagens locais. Apague-o integralmente ao criar um artigo
novo. Para a equipe de diagramação, `make modelo` gera uma prévia isolada em
`build/modelo/preview.pdf`.

Antes de enviar, confira: resumo/abstract com no máximo 250 palavras; até cinco
palavras-chave sem repetir o título; e-mail e ORCID de cada autor; resultados
verificáveis; declarações CRediT, conflito de interesses e aprovação ética;
referências em conformidade com ABNT.

Após receber a pasta, a equipe integradora adiciona ao `livro.tex`:

```tex
\begin{refsection}
  \import{artigos/artigo_04/}{artigo.tex}
\end{refsection}
```
