PROJECT := ArniePye
PACKAGE := arniepye
SOURCES := Makefile setup.py

ENV := env
DEPENTS_CI := $(ENV)/.depends.ci
DEPENDS_DEV := $(ENV)/.depends.dev
EGG_INFO := $(subst -,_,$(PROJECT)).egg-info

PLATFORM := $(shell python -c 'import sys; print(sys.platform)')

ifneq ($(findstring win32, $(PLATFORM)), )
	SYS_PYTHON := C:\\Python33\\python.exe
	SYS_VIRTUALENV := C:\\Python33\\Scripts\\virtualenv.exe
	BIN := $(ENV)/Scripts
	EXE := .exe
	OPEN := cmd /c start
	# https://bugs.launchpad.net/virtualenv/+bug/449537
	export TCL_LIBRARY=C:\\Python33\\tcl\\tcl8.5
else
	SYS_PYTHON := python3
	SYS_VIRTUALENV := virtualenv
	BIN := $(ENV)/bin
	ifneq ($(findstring cygwin, $(PLATFORM)), )
		OPEN := cygstart
	else
		OPEN := open
	endif
endif

MAN := man
SHARE := share

PYTHON := $(BIN)/python$(EXE)
PIP := $(BIN)/pip$(EXE)
RST2HTML := $(BIN)/rst2html.py
PDOC := $(BIN)/pdoc
PEP8 := $(BIN)/pep8$(EXE)
PEP257 := $(BIN)/pep257$(EXE)
PYLINT := $(BIN)/pylint$(EXE)
NOSE := $(BIN)/nosetests$(EXE)

# Installation ###############################################################

.PHONY: all
all: env

.PHONY: env
env: .virtualenv $(EGG_INFO)
$(EGG_INFO): Makefile setup.py
	$(PYTHON) setup.py develop
	touch $(EGG_INFO)  # flag to indicate package is installed

.PHONY: .virtualenv
.virtualenv: $(PIP)
$(PIP):
	$(SYS_VIRTUALENV) --python $(SYS_PYTHON) $(ENV)

.PHONY: depends
depends: .depends-ci .depends-dev

.PHONY: .depends-ci
.depends-ci: .virtualenv Makefile $(DEPENTS_CI)
$(DEPENTS_CI): Makefile
	$(PIP) install pep8 pep257 nose coverage
	touch $(DEPENTS_CI)  # flag to indicate dependencies are installed

.PHONY: .depends-dev
.depends-dev: .virtualenv Makefile $(DEPENDS_DEV)
$(DEPENDS_DEV): Makefile
	$(PIP) install docutils pdoc pylint wheel
	touch $(DEPENDS_DEV)  # flag to indicate dependencies are installed

# Documentation ##############################################################

.PHONY: doc
doc: readme apidocs

.PHONY: readme
readme: .depends-ci docs/README-github.html docs/README-pypi.html
docs/README-github.html: README.md
	pandoc -f markdown_github -t html -o docs/README-github.html README.md
docs/README-pypi.html: README.rst
	$(PYTHON) $(RST2HTML) README.rst docs/README-pypi.html
README.rst: README.md
	pandoc -f markdown_github -t rst -o README.rst README.md

.PHONY: apidocs
apidocs: .depends-ci apidocs/$(PACKAGE)/index.html
apidocs/$(PACKAGE)/index.html: $(SOURCES)
	$(PYTHON) $(PDOC) --html --overwrite $(PACKAGE) --html-dir apidocs

.PHONY: read
read: doc
	$(OPEN) apidocs/$(PACKAGE)/index.html
	$(OPEN) docs/README-pypi.html
	$(OPEN) docs/README-github.html

# Static Analysis ############################################################

.PHONY: pep8
pep8: env .depends-ci
	$(PEP8) $(PACKAGE) --ignore=E501

.PHONY: pep257
pep257: env .depends-ci
	$(PEP257) $(PACKAGE) --ignore=E501

.PHONY: pylint
pylint: env .depends-dev
	$(PYLINT) $(PACKAGE) --reports no \
	                     --msg-template="{msg_id}:{line:3d},{column}:{msg}" \
	                     --max-line-length=79 \
	                     --disable=I0011,W0142,W0511,R0801

.PHONY: check
check: pep8 pep257 pylint

# Testing ####################################################################

.PHONY: test
test: env .depends-ci
	$(NOSE)

.PHONY: tests
tests: env .depends-ci
	TEST_INTEGRATION=1 $(NOSE) --verbose --stop --cover-package=$(PACKAGE)

.PHONY: ci
ci: pep8 pep257 test tests

# Cleanup ####################################################################

.PHONY: clean
clean: .clean-dist .clean-test .clean-doc .clean-build

.PHONY: clean-all
clean-all: clean .clean-env

.PHONY: .clean-env
.clean-env:
	rm -rf $(ENV)

.PHONY: .clean-build
.clean-build:
	find $(PACKAGE) -name '*.pyc' -delete
	find $(PACKAGE) -name '__pycache__' -delete
	rm -rf *.egg-info

.PHONY: .clean-doc
.clean-doc:
	rm -rf apidocs docs/README*.html README.rst

.PHONY: .clean-test
.clean-test:
	rm -rf .coverage

.PHONY: .clean-dist
.clean-dist:
	rm -rf dist build

# Release ####################################################################

.PHONY: .git-no-changes
.git-no-changes:
	@if git diff --name-only --exit-code;         \
	then                                          \
		echo Git working copy is clean...;        \
	else                                          \
		echo ERROR: Git working copy is dirty!;   \
		echo Commit your changes and try again.;  \
		exit -1;                                  \
	fi;

.PHONY: dist
dist: .git-no-changes env depends check test tests doc
	$(PYTHON) setup.py sdist
	$(MAKE) read

.PHONY: upload
upload: .git-no-changes env depends doc
	$(PYTHON) setup.py sdist upload -r arnie
	$(MAKE) dev  # restore the development environment

.PHONY: dev
dev:
	python setup.py develop

# Demo #######################################################################

.PHONY: demo
demo: serve

	# This demo starts a local server and verifies that bootstrap.py
	# installs ArniePye into a new virtualenv.

	# Create a temporary virtualenv for the demo and bootstrap ArniePye
	- virtualenv --python $(VERSION) demo ; cd demo ;\
	wget http://127.0.0.1:8080/packages/bootstrap/bootstrap.py ;\
	Scripts/python.exe bootstrap.py

	# Use 'arnie' to install and uninstall another package
	- demo/Scripts/arnie install testpackage
	- demo/Scripts/arnie uninstall testpackage

	# Clean up the demo and prompt the user to stop the server
	- rm -rf demo
	@echo
	@echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	@echo !!! press Ctrl+C to stop the server !!!
	@echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

.PHONY: demo2
demo2: serve

	# This demo starts a local server and verifies that bootstrap.bat
	# installs Python 2 and 3 then runs bootstrap.py.

	# Create a temporary virtualenv for the demo and bootstrap ArniePye
	- mkdir demo2 ; cd demo2 ;\
	wget http://127.0.0.1:8080/packages/bootstrap/bootstrap.bat ;\
	cmd /c bootstrap.bat

	# Clean up the demo and prompt the user to stop the server
	- rm -rf demo2
	@echo
	@echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	@echo !!! press Ctrl+C to stop the server !!!
	@echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

.PHONY: serve
serve: develop

	# Start a local PyPI server in the background
	$(BIN)/arnie serve --temp --verbose &

	# Upload the current version of ArniePye to the server
	$(PYTHON) setup.py sdist upload -r local

	# Notify the user that the server is still running
	@echo
	@echo press Ctrl+C when done serving...
