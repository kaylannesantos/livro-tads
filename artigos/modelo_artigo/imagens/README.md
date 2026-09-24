# Imagens do artigo

Inclua aqui imagens TIFF ou JPEG, com no mínimo 300 DPI. Insira cada figura no
ponto pertinente do texto, numerada na ordem da primeira menção e centralizada.

O comando `\inserirfigura` segue o fluxo do `template_tcc_monografia`: usa
`figure[H]`, identificação acima no formato “Figura 1 – Título”, rótulo para
citação e fonte abaixo via `\legend`. Exemplo:

```tex
Como mostra a Figura~\ref{fig:cpu}, a CPU participa do processamento do jogo.

\inserirfigura[0.42\textwidth]
  {fig:cpu}
  {CPU como componente de processamento de um jogo digital}
  {imagens/imagem_01.png}
  {Imagem ilustrativa do modelo (2026).}
```

O resultado é `Figura 1 – Ícone ilustrativo de processamento` em Arial Narrow
11. Tabelas seguem a mesma nomenclatura, com título acima e fonte abaixo; use
`\caption`, `\label` e `\legend` dentro de `table`, como no exemplo do artigo.
Não use figuras no fim do artigo: elas devem ficar próximas ao trecho que as
apresenta.
