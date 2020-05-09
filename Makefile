ifneq (,)
.error This Makefile requires GNU Make.
endif

# -------------------------------------------------------------------------------------------------
# Can be changed
# -------------------------------------------------------------------------------------------------
# This can be adjusted
PYTHON_VERSION = 2.7


# -------------------------------------------------------------------------------------------------
# Default configuration
# -------------------------------------------------------------------------------------------------
.PHONY: help lint code test smoke autoformat docs pipeline build deploy clean

BINPATH = bin/
MANPATH = man/
DOCPATH = docs/
BINNAME = pwncat

FL_VERSION = 0.3
FL_IGNORES = .git/,.github/,$(BINNAME).egg-info,docs/$(BINNAME).api.html,docs/,data/,.mypy_cache/

UID := $(shell id -u)
GID := $(shell id -g)


# -------------------------------------------------------------------------------------------------
# Default Target
# -------------------------------------------------------------------------------------------------
help:
	@echo " ██▓███   █     █░ ███▄    █  ▄████▄   ▄▄▄      ▄▄▄█████▓"
	@echo "▓██░  ██▒▓█░ █ ░█░ ██ ▀█   █ ▒██▀ ▀█  ▒████▄    ▓  ██▒ ▓▒"
	@echo "▓██░ ██▓▒▒█░ █ ░█ ▓██  ▀█ ██▒▒▓█    ▄ ▒██  ▀█▄  ▒ ▓██░ ▒░"
	@echo "▒██▄█▓▒ ▒░█░ █ ░█ ▓██▒  ▐▌██▒▒▓▓▄ ▄██▒░██▄▄▄▄██ ░ ▓██▓ ░ "
	@echo "▒██▒ ░  ░░░██▒██▓ ▒██░   ▓██░▒ ▓███▀ ░ ▓█   ▓██▒  ▒██▒ ░ "
	@echo "▒▓▒░ ░  ░░ ▓░▒ ▒  ░ ▒░   ▒ ▒ ░ ░▒ ▒  ░ ▒▒   ▓▒█░  ▒ ░░   "
	@echo "░▒ ░       ▒ ░ ░  ░ ░░   ░ ▒░  ░  ▒     ▒   ▒▒ ░    ░    "
	@echo "░░         ░   ░     ░   ░ ░ ░          ░   ▒     ░      "
	@echo "             ░             ░ ░ ░            ░  ░         "
	@echo "                             ░                           "
	@echo
	@echo "lint             Lint repository"
	@echo "code             Lint source code"
	@echo "test             Run integration tests"
	@echo "smoke            Run smokke tests (dockerized)"
	@echo "autoformat       Autoformat code according to Python black"
	@echo
	@echo "docs             Update code documentation"
	@echo "pipeline         Update GitHub action workflow pipelines"
	@echo
	@echo "build            Build Python pkg, source and binary dist"
	@echo "deploy           Deploy pip package"
	@echo "clean            Clean the Build"


# -------------------------------------------------------------------------------------------------
# Lint Targets
# -------------------------------------------------------------------------------------------------
lint: _lint-files
lint: _lint-version
lint: _lint-usage
lint: _lint-docs
lint: _lint-man
lint: _lint-pipeline

.PHONY: _lint-version
_lint-version:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Check version config"
	@echo "# -------------------------------------------------------------------- #"
	@VERSION_PWNCAT=$$( grep -E '^VERSION = "[.0-9]+(-\w+)?"' bin/pwncat | awk -F'"' '{print $$2}' || true ); \
	VERSION_SETUP=$$( grep version= setup.py | awk -F'"' '{print $$2}' || true ); \
	VERSION_CHANGE=$$( grep -E '## Release [.0-9]+(-\w+)?$$' CHANGELOG.md | head -1 | sed 's/.*[[:space:]]//g' || true ); \
	if [ "$${VERSION_PWNCAT}" != "$${VERSION_SETUP}" ] || [ "$${VERSION_SETUP}" != "$${VERSION_CHANGE}" ]; then \
		echo "[ERROR] Version mismatch"; \
		echo "bin/pwncat:   $${VERSION_PWNCAT}"; \
		echo "setup.py:     $${VERSION_SETUP}"; \
		echo "CHANGELOG.md: $${VERSION_CHANGE}    # Looking for latest entry with regex format: '## Release [.0-9]+(\w+)?$$'" ; \
		exit 1; \
	else \
		echo "[OK] Version match"; \
		echo "bin/pwncat:   $${VERSION_PWNCAT}"; \
		echo "setup.py:     $${VERSION_SETUP}"; \
		echo "CHANGELOG.md: $${VERSION_CHANGE}"; \
		exit 0; \
	fi \

.PHONY: _lint-usage
_lint-usage: SHELL := /bin/bash
_lint-usage:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Lint usage"
	@echo "# -------------------------------------------------------------------- #"
	$(PWD)/tests/bin/check-usage.sh

.PHONY: _lint-files
_lint-files:
	@echo "# --------------------------------------------------------------------"
	@echo "# Lint files"
	@echo "# -------------------------------------------------------------------- #"
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-cr --text --ignore '$(FL_IGNORES)' --path .
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-crlf --text --ignore '$(FL_IGNORES)' --path .
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-trailing-single-newline --text --ignore '$(FL_IGNORES)' --path .
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-trailing-space --text --ignore '$(FL_IGNORES)' --path .
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-utf8 --text --ignore '$(FL_IGNORES)' --path .
	@docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/file-lint:$(FL_VERSION) file-utf8-bom --text --ignore '$(FL_IGNORES)' --path .

.PHONY: _lint-docs
_lint-docs:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Lint docs"
	@echo "# -------------------------------------------------------------------- #"
	@$(MAKE) --no-print-directory docs
	git diff --quiet -- $(DOCPATH) || { echo "Build Changes"; git diff | cat; git status; false; }

.PHONY: _lint-man
_lint-man:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Lint man page"
	@echo "# -------------------------------------------------------------------- #"
	@$(MAKE) --no-print-directory man
	git diff --quiet -- $(DOCPATH) $(MANPATH) || { echo "Build Changes"; git diff | cat; git status; false; }

.PHONY: _lint-pipeline
_lint-pipeline:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Lint Pipelines"
	@echo "# -------------------------------------------------------------------- #"
	@$(MAKE) --no-print-directory pipeline
	git diff --quiet -- .github/workflows || { echo "Build Changes"; git diff | cat; git status; false; }


# -------------------------------------------------------------------------------------------------
# Code Style Targets
# -------------------------------------------------------------------------------------------------
code: _code-pycodestyle
code: _code-pydocstyle
code: _code-pylint
code: _code-black
code: _code-mypy

.PHONY: _code-pycodestyle
_code-pycodestyle:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Check pycodestyle"
	@echo "# -------------------------------------------------------------------- #"
	docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data --entrypoint= cytopia/pycodestyle sh -c ' \
		mkdir -p /tmp \
		&& cp $(BINPATH)$(BINNAME) /tmp/$(BINNAME).py \
		&& pycodestyle --config=setup.cfg /tmp/$(BINNAME).py'

.PHONY: _code-pydocstyle
_code-pydocstyle:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Check pycodestyle"
	@echo "# -------------------------------------------------------------------- #"
	docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data --entrypoint= cytopia/pydocstyle sh -c ' \
		mkdir -p /tmp \
		&& cp $(BINPATH)$(BINNAME) /tmp/$(BINNAME).py \
		&& pydocstyle --explain --config=setup.cfg /tmp/$(BINNAME).py'

.PHONY: _code-pylint
_code-pylint:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Check pylint"
	@echo "# -------------------------------------------------------------------- #"
	docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data cytopia/pylint --rcfile=setup.cfg $(BINPATH)$(BINNAME)

.PHONY: _code-black
_code-black:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Check Python Black"
	@echo "# -------------------------------------------------------------------- #"
	docker run --rm $$(tty -s && echo "-it" || echo) -v ${PWD}:/data cytopia/black -l 100 --check --diff $(BINPATH)$(BINNAME)

.PHONY: _code-mypy
_code-mypy:
	@echo "# -------------------------------------------------------------------- #"
	@echo "# Check mypy"
	@echo "# -------------------------------------------------------------------- #"
	docker run --rm $$(tty -s && echo "-it" || echo) -v ${PWD}:/data cytopia/mypy --config-file setup.cfg $(BINPATH)$(BINNAME)


# -------------------------------------------------------------------------------------------------
# Smoke Targets
# -------------------------------------------------------------------------------------------------
smoke: _smoke-keep_open-before_send
smoke: _smoke-keep_open-after_client_send

.PHONY:
_smoke-keep_open-before_send:
	@# It's sometimes a race-condition, so we run it five times
	tests/smoke/run.sh "200---tcp---keep_open" "server_1" "client_1" "$(PYTHON_VERSION)"
	tests/smoke/run.sh "200---tcp---keep_open" "server_1" "client_1" "$(PYTHON_VERSION)"
	tests/smoke/run.sh "200---tcp---keep_open" "server_1" "client_1" "$(PYTHON_VERSION)"
	tests/smoke/run.sh "200---tcp---keep_open" "server_1" "client_1" "$(PYTHON_VERSION)"
	tests/smoke/run.sh "200---tcp---keep_open" "server_1" "client_1" "$(PYTHON_VERSION)"

_smoke-keep_open-after_client_send:
	@# It's sometimes a race-condition, so we run it five times
	tests/smoke/run.sh "200---tcp---keep_open" "server_2" "client_2" "$(PYTHON_VERSION)"
	tests/smoke/run.sh "200---tcp---keep_open" "server_2" "client_2" "$(PYTHON_VERSION)"
	tests/smoke/run.sh "200---tcp---keep_open" "server_2" "client_2" "$(PYTHON_VERSION)"
	tests/smoke/run.sh "200---tcp---keep_open" "server_2" "client_2" "$(PYTHON_VERSION)"
	tests/smoke/run.sh "200---tcp---keep_open" "server_2" "client_2" "$(PYTHON_VERSION)"


# -------------------------------------------------------------------------------------------------
# Test Targets
# -------------------------------------------------------------------------------------------------
TEST_PWNCAT_HOST=localhost
TEST_PWNCAT_PORT=4444
TEST_PWNCAT_WAIT=8
TEST_PWNCAT_RUNS=1
test: _test-behaviour-quit--client
test: _test-behaviour-quit--server
test: _test-mode--local_forward
test: _test-mode--remote_forward
test: _test-options--nodns
test: _test-options--crlf
test: _test-options--keep_open
test: _test-options--reconn
test: _test-options--ping_intvl
test: _test-options--ping_word

.PHONY: _test-behaviour-quit--client
_test-behaviour-quit--client:
	tests/integration/run.sh "01-behaviour-quit--client" \
		"$(TEST_PWNCAT_HOST)" "$(TEST_PWNCAT_PORT)" "$(TEST_PWNCAT_WAIT)" "$(TEST_PWNCAT_RUNS)"

.PHONY: _test-behaviour-quit--server
_test-behaviour-quit--server:
	tests/integration/run.sh "02-behaviour-quit--server" \
		"$(TEST_PWNCAT_HOST)" "$(TEST_PWNCAT_PORT)" "$(TEST_PWNCAT_WAIT)" "$(TEST_PWNCAT_RUNS)"

.PHONY: _test-mode--local_forward
_test-mode--local_forward:
	tests/integration/run.sh "10-mode---local_forward" \
		"$(TEST_PWNCAT_HOST)" "$(TEST_PWNCAT_PORT)" "$(TEST_PWNCAT_WAIT)" "$(TEST_PWNCAT_RUNS)"

.PHONY: _test-mode--remote_forward
_test-mode--remote_forward:
	tests/integration/run.sh "11-mode---remote_forward" \
		"$(TEST_PWNCAT_HOST)" "$(TEST_PWNCAT_PORT)" "$(TEST_PWNCAT_WAIT)" "$(TEST_PWNCAT_RUNS)"

.PHONY: _test-options--nodns
_test-options--nodns:
	tests/integration/run.sh "20-options---nodns" \
		"$(TEST_PWNCAT_HOST)" "$(TEST_PWNCAT_PORT)" "$(TEST_PWNCAT_WAIT)" "$(TEST_PWNCAT_RUNS)"

.PHONY: _test-options--crlf
_test-options--crlf:
	tests/integration/run.sh "21-options---crlf" \
		"$(TEST_PWNCAT_HOST)" "$(TEST_PWNCAT_PORT)" "$(TEST_PWNCAT_WAIT)" "$(TEST_PWNCAT_RUNS)"

.PHONY: _test-options--keep_open
_test-options--keep_open:
	tests/integration/run.sh "22-options---keep_open" \
		"$(TEST_PWNCAT_HOST)" "$(TEST_PWNCAT_PORT)" "$(TEST_PWNCAT_WAIT)" "$(TEST_PWNCAT_RUNS)"

.PHONY: _test-options--reconn
_test-options--reconn:
	tests/integration/run.sh "23-options---reconn" \
		"$(TEST_PWNCAT_HOST)" "$(TEST_PWNCAT_PORT)" "$(TEST_PWNCAT_WAIT)" "$(TEST_PWNCAT_RUNS)"

.PHONY: _test-options--ping_init
_test-options--ping_intvl:
	tests/integration/run.sh "25-options---ping_intvl" \
		"$(TEST_PWNCAT_HOST)" "$(TEST_PWNCAT_PORT)" "$(TEST_PWNCAT_WAIT)" "$(TEST_PWNCAT_RUNS)"

.PHONY: _test-options--ping_word
_test-options--ping_word:
	tests/integration/run.sh "26-options---ping_word" \
		"$(TEST_PWNCAT_HOST)" "$(TEST_PWNCAT_PORT)" "$(TEST_PWNCAT_WAIT)" "$(TEST_PWNCAT_RUNS)"


# -------------------------------------------------------------------------------------------------
# Documentation
# -------------------------------------------------------------------------------------------------
docs: _docs-man
docs: _docs-api
docs: _docs-mypy_type_coverage

.PHONY: _docs-man
_docs-man: $(BINPATH)$(BINNAME)
	docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data -w /data -e UID=$(UID) -e GID=${GID} python:3-alpine sh -c ' \
		apk add help2man \
		&& help2man -n $(BINNAME) --no-info --source=https://github.com/cytopia/pwncat -s 1 -o $(MANPATH)$(BINNAME).1 $(BINPATH)$(BINNAME) \
		&& chown $${UID}:$${GID} $(MANPATH)$(BINNAME).1'
	docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data -w /data -e UID=$(UID) -e GID=${GID} python:3-alpine sh -c ' \
		apk add groff \
		&& cat $(MANPATH)$(BINNAME).1 | groff -mandoc -Thtml | sed "s/.*CreationDate:.*//g" > $(DOCPATH)$(BINNAME).man.html \
		&& chown $${UID}:$${GID} $(DOCPATH)$(BINNAME).man.html'

.PHONY: _docs-api
_docs-api:
	@# Generate pdoc API page
	docker run --rm $$(tty -s && echo "-it" || echo) -v $(PWD):/data -w /data -e UID=$(UID) -e GID=${GID} python:3-alpine sh -c ' \
		pip install pdoc3 \
		&& mkdir -p /tmp \
		&& cp $(BINPATH)$(BINNAME) /tmp/$(BINNAME).py \
		&& pdoc3 -f -o $(DOCPATH) --html --config show_inherited_members=False /tmp/$(BINNAME).py \
		&& mv $(DOCPATH)$(BINNAME).html $(DOCPATH)$(BINNAME).api.html \
		&& chown $${UID}:$${GID} $(DOCPATH)$(BINNAME).api.html'

.PHONY: _docs-mypy_type_coverage
_docs-mypy_type_coverage:
	@# Generate mypy code coverage page
	docker run --rm $$(tty -s && echo "-it" || echo) -v ${PWD}:/data -w /data -e UID=$(UID) -e GID=${GID} --entrypoint= cytopia/mypy sh -c ' \
		mypy --config-file setup.cfg --html-report tmp $(BINPATH)$(BINNAME) \
		&& cp -f tmp/mypy-html.css docs/css/mypy.css \
		&& cat tmp/index.html \
			| sed "s|mypy-html.css|css/mypy.css|g" \
			| sed "s|<a.*</a>|bin/pwncat|g" \
			> docs/pwncat.type.html \
		&& cat tmp/html/bin/pwncat.html \
			| sed "s|../../mypy-html.css|mypy.css|g" \
			| sed "s|__main__|pwncat|g" \
			>> docs/pwncat.type.html \
		&& chown $${UID}:$${GID} docs/pwncat.type.html \
		&& chown $${UID}:$${GID} docs/css/mypy.css \
		&& rm -r tmp/'
	@# Update code coverage in README.md
	docker run --rm $$(tty -s && echo "-it" || echo) -v ${PWD}:/data -w /data python:3-alpine sh -c ' \
		apk add bc \
		&& percent=$$(grep "% imprecise" docs/pwncat.type.html | grep "th" | grep -Eo "[.0-9]+") \
		&& coverage=$$(echo "100 - $${percent}" | bc) \
		&& sed -i "s/fully typed: \([.0-9]*\)/fully typed: $${coverage}/g" README.md'


# -------------------------------------------------------------------------------------------------
# Generate GitHub Action workflow pipelines
# -------------------------------------------------------------------------------------------------
pipeline:
	$(PWD)/tests/pipelines/run.sh


# -------------------------------------------------------------------------------------------------
# Build Targets
# -------------------------------------------------------------------------------------------------
build: clean
build: _lint-version
build: _build-source_dist
build: _build-binary_dist
build: _build-python_package
build: _build-check_python_package

.PHONY: _build_source_dist
_build-source_dist:
	@echo "Create source distribution"
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(PYTHON_VERSION)-alpine \
		python setup.py sdist

.PHONY: _build_binary_dist
_build-binary_dist:
	@echo "Create binary distribution"
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(PYTHON_VERSION)-alpine \
		python setup.py bdist_wheel --universal

.PHONY: _build_python_package
_build-python_package:
	@echo "Build Python package"
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		-u $$(id -u):$$(id -g) \
		python:$(PYTHON_VERSION)-alpine \
		python setup.py build

.PHONY: _build_check_python_package
_build-check_python_package:
	@echo "Check Python package"
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		python:$(PYTHON_VERSION)-alpine \
		sh -c "pip install twine \
		&& twine check dist/*"


# -------------------------------------------------------------------------------------------------
# Publish Targets
# -------------------------------------------------------------------------------------------------
deploy:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		python:$(PYTHON_VERSION)-alpine \
		sh -c "pip install twine \
		&& twine upload dist/*"


# -------------------------------------------------------------------------------------------------
# Misc Targets
# -------------------------------------------------------------------------------------------------
autoformat:
	docker run \
		--rm \
		$$(tty -s && echo "-it" || echo) \
		-v $(PWD):/data \
		-w /data \
		cytopia/black -l 100 $(BINPATH)$(BINNAME)

clean:
	-rm -rf $(BINNAME).egg-info/
	-rm -rf dist/
	-rm -rf build/
