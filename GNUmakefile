# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)
all::
pkg = olddoc
RUBY = ruby
VERSION := $(shell $(RUBY) -Ilib -rolddoc -e 'puts Olddoc::VERSION')

check-warnings:
	@(for i in $$(git ls-files '*.rb'| grep -v '^setup\.rb$$'); \
	  do $(RUBY) -d -W2 -c $$i; done) | grep -v '^Syntax OK$$' || :

pkggem := pkg/$(pkg)-$(VERSION).gem
fix-perms:
	git ls-tree -r HEAD | awk '/^100644 / {print $$NF}' | xargs chmod 644
	git ls-tree -r HEAD | awk '/^100755 / {print $$NF}' | xargs chmod 755
gem-man:
	$(MAKE) -C Documentation/ gem-man

pkg_extra := NEWS

.manifest: fix-perms
	$(RUBY) -I lib bin/olddoc prepare
	rm -rf man
	(git ls-files; \
	 for i in $(pkg_extra); do echo $$i; done) | \
	 LC_ALL=C sort > $@+
	cmp $@+ $@ || mv $@+ $@; rm -f $@+

placeholders := olddoc_5 olddoc_1

$(placeholders):
	echo olddoc_placeholder > $@

.gem-manifest: .manifest gem-man $(placeholders)
	(ls man/*.?; cat .manifest) | LC_ALL=C sort > $@+
	cmp $@+ $@ || mv $@+ $@; rm -f $@+

doc: $(placeholders)
	$(MAKE) -C Documentation html
	rm -rf doc
	olddoc prepare
	rdoc --debug -f oldweb
	olddoc merge
	ln NEWS.atom.xml doc/

gem: $(pkggem)

install-gem: $(pkggem)
	gem install $(CURDIR)/$<

$(pkggem): fix-perms .gem-manifest
	VERSION=$(VERSION) gem build $(pkg).gemspec
	mkdir -p pkg
	mv $(@F) $@

package: $(pkggem)

.PHONY: all .FORCE-GIT-VERSION-FILE NEWS
.PHONY: check-warnings fix-perms doc
