# Imagens do artigo

Inclua aqui imagens TIFF ou JPEG, com no mínimo 300 DPI. Insira cada figura no
ponto pertinente do texto, numerada na ordem da primeira menção e centralizada.

O comando `\inserirfigura` segue o fluxo do `template_tcc_monografia`: usa
`figure[H]`, legenda acima, rótulo para citação e fonte abaixo. Exemplo:

```tex
Como mostra a Figura~\ref{fig:cpu}, o componente é apenas ilustrativo.

\inserirfigura[0.42\textwidth]
  {fig:cpu}
  {Ícone ilustrativo de processamento}
  {imagens/imagem_01.png}
  {Elaboração própria (2026).}
```

O resultado é `Figura 1: Ícone ilustrativo de processamento` em Arial Narrow
11. Não use figuras no fim do artigo: elas devem ficar próximas ao trecho que
as apresenta.
