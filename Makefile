################################################################
################################################################
# Makefile for LaTeX3 "dandelion" files                        #
################################################################
################################################################

################################################################
# Default with no target is to give help                       #
################################################################

help:
	@echo ""
	@echo " make clean            - clean out current directory"
	@echo " make doc              - typeset documentation"
	@echo " make localinstall     - install files in local texmf tree"
	@echo " make unpack           - extract packages"
	@echo ""

##############################################################
# Master package name                                        #
##############################################################

PACKAGE = dandelion

##############################################################
# Data for local installation and TDS construction           #
##############################################################

PACKAGEROOT := latex/$(PACKAGE)

##############################################################
# Details of source files                                    #
##############################################################

DTX       = $(subst ,,$(notdir $(wildcard *.dtx)))
DTXFILES  = $(subst .dtx,,$(notdir $(wildcard *.dtx)))
TEX       = $(subst ,,$(notdir $(wildcard *.tex)))
UNPACK    = $(PACKAGE).ins

##############################################################
# Clean-up information                                       #
##############################################################

AUXFILES = \
	aux  \
	glo  \
	hd   \
	idx  \
	log  \
	out

CLEAN = \
	gz   \
	pdf  \
	sty  \
	zip

################################################################
# File building: default actions                               #
################################################################

%.pdf: %.dtx
	@NAME=`basename $< .dtx` ; \
	echo "Typesetting $$NAME" ; \
	pdflatex -draftmode -interaction=nonstopmode "\input $<" > /dev/null ; \
	if [ $$? = 0 ] ; then  \
	  makeindex -q -s l3doc.ist -o $$NAME.ind $$NAME.idx > /dev/null ; \
	  pdflatex -interaction=nonstopmode "\input $<" > /dev/null ; \
	  pdflatex -interaction=nonstopmode "\input $<" > /dev/null ; \
	  if [ `grep 'defined but not documented' $$NAME.log | wc -l` -ne 0 ] ; then \
	    echo "! Warning: some functions defined but not documented" ; \
	  fi ; \
	  if [ `grep 'documented but not defined' $$NAME.log | wc -l` -ne 0 ]  ; then \
	    echo "! Warning: some functions documented but not defined" ; \
	  fi ; \
	else \
	  echo "  Compilation failed" ; \
	fi ; \
	for I in $(AUXFILES) ; do \
	  rm -f $$NAME.$$I ; \
	done

################################################################
# User make options                                            #
################################################################

.PHONY = \
	clean  \
	doc    \
	unpack

clean:
	@for I in $(AUXFILES) $(CLEAN) ; do \
	  rm -f *.$$I ; \
	done

doc: unpack $(foreach FILE,$(DTXFILES),$(FILE).pdf)

unpack:
	@echo "Unpacking files"
	for I in $(UNPACK) ; do \
	  tex $$I > /dev/null ; \
	done