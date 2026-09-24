# Ambiente de compilação reproduzível para o livro.
# Pode-se trocar a imagem sem editar este arquivo:
#   make pdf TEXLIVE_IMAGE=ghcr.io/xu-cheng/texlive-full:latest

TEXLIVE_IMAGE ?= ghcr.io/xu-cheng/texlive-full:latest
DOCKER ?= docker
DOCKER_RUN = $(DOCKER) run --rm --user $$(id -u):$$(id -g) --env XDG_CACHE_HOME=/work/build/.cache --volume "$(CURDIR):/work" --workdir /work $(TEXLIVE_IMAGE)
LATEXMK = latexmk -xelatex -interaction=nonstopmode -halt-on-error -file-line-error -outdir=build livro.tex

.PHONY: help image pdf modelo watch clean

help:
	@printf '%s\n' \
	  'make pdf    Compila build/livro.pdf em um container TeX Live.' \
	  'make modelo Compila somente a prévia do modelo de artigo.' \
	  'make watch  Recompila ao salvar arquivos .tex ou .bib (Ctrl+C para parar).' \
	  'make clean  Remove os artefatos locais de compilação.' \
	  'make image  Baixa/atualiza a imagem TeX Live usada na compilação.'

image:
	$(DOCKER) pull $(TEXLIVE_IMAGE)

pdf:
	@mkdir -p build/.cache
	$(DOCKER_RUN) $(LATEXMK)

modelo:
	@mkdir -p build/modelo/.cache
	$(DOCKER_RUN) latexmk -xelatex -interaction=nonstopmode -halt-on-error -file-line-error -outdir=build/modelo artigos/modelo_artigo/preview.tex

watch:
	@mkdir -p build/.cache
	$(DOCKER_RUN) latexmk -pvc -xelatex -interaction=nonstopmode -halt-on-error -file-line-error -outdir=build livro.tex

clean:
	@mkdir -p build
	$(DOCKER_RUN) latexmk -C -outdir=build livro.tex
	@rmdir build 2>/dev/null || true
