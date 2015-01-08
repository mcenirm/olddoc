# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)
all::

INSTALL = install
PANDOC = pandoc
PANDOC_OPTS = -f markdown --email-obfuscation=none
pandoc = $(PANDOC) $(PANDOC_OPTS)
pandoc_html = $(pandoc) --toc -t html --no-wrap


man1 := olddoc.1
man5 := olddoc.5
man7 :=

html1 := $(addsuffix .html, $(man1))
html5 := $(addsuffix .html, $(man5))
html7 := $(addsuffix .html, $(man7))

all:: man

man: $(man1) $(man5) $(man7)
html: $(html1) $(html5) $(html7)

prefix ?= $(HOME)
mandir ?= $(prefix)/share/man
man1dir = $(mandir)/man1
man5dir = $(mandir)/man5
man7dir = $(mandir)/man7

gem-man: man
	$(INSTALL) -d -m 755 ../man
	test -z "$(man1)" || $(INSTALL) -m 644 $(man1) ../man
	test -z "$(man5)" || $(INSTALL) -m 644 $(man5) ../man
	test -z "$(man7)" || $(INSTALL) -m 644 $(man7) ../man

install-man: man
	$(INSTALL) -d -m 755 $(DESTDIR)$(mandir)
	test -z "$(man1)" || $(INSTALL) -d -m 755 $(DESTDIR)$(man1dir)
	test -z "$(man5)" || $(INSTALL) -d -m 755 $(DESTDIR)$(man5dir)
	test -z "$(man7)" || $(INSTALL) -d -m 755 $(DESTDIR)$(man7dir)
	test -z "$(man1)" || $(INSTALL) -m 644 $(man1) $(DESTDIR)$(man1dir)
	test -z "$(man5)" || $(INSTALL) -m 644 $(man5) $(DESTDIR)$(man5dir)
	test -z "$(man7)" || $(INSTALL) -m 644 $(man7) $(DESTDIR)$(man7dir)

%: %.txt
	$(pandoc) -s -t man < $< > $@+ && mv $@+ $@

%.html : %.txt
	$(pandoc_html) < $< > $@+ && mv $@+ $@

clean::
	$(RM) $(man1) $(man5) $(man7) $(html1) $(html5) $(html7)
