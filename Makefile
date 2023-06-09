.DEFAULT_GOAL	:= help
# TODO: test oneshell target (https://www.gnu.org/software/make/manual/html_node/One-Shell.html)
.ONESHELL:
export SHELL 	:= $(shell which sh)
# .SHELLFLAGS 	:= -eu -o pipefail -c
# MAKEFLAGS 		+= --warn-undefined-variables

# ENV VARS
export UNAME 	:= $(shell uname -s)

ifeq ($(UNAME), Darwin)
	export XCODE := $(shell xcode-select --install >/dev/null 2>&1; echo $$?)
endif

ifeq ($(UNAME), Darwin)
	export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK := 1
endif

ifeq ($(shell command -v brew >/dev/null 2>&1; echo $$?), 0)
	export BREW := $(shell which brew)
endif

ifeq ($(shell command -v python >/dev/null 2>&1; echo $$?), 0)
	export PYTHON := $(shell which python3)
endif

ifeq ($(shell command -v pip >/dev/null 2>&1; echo $$?), 0)
	export PIP := $(shell which pip3)
endif

ifneq (,$(wildcard /etc/os-release))
	include /etc/os-release
endif

# colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

# targets
.PHONY: all
all: install sanity-check xcode homebrew git python pip nodejs just

# TODO: QA Linux (Debian/Ubuntu); nodejs
# * cf. `distrobox create --name i-use-arch-btw --image archlinux:latest && distrobox enter i-use-arch-btw`
# * || `distrobox create --name debby --image debian:stable && distrobox enter debby`

sanity-check:  ## output environment variables
	@echo "Checking environment..."
	@echo "UNAME: ${UNAME}"
	@echo "SHELL: ${SHELL}"
	@echo "ID: ${ID}"
	@echo "XCODE: ${XCODE}"
	@echo "BREW: ${BREW}"
	@echo "HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK: ${HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK}"
	@echo "PYTHON: ${PYTHON}"
	@echo "PIP: ${PIP}"

xcode: ## install xcode command line tools
	@echo "Installing Xcode command line tools..."
	if [ "${UNAME}" == "Darwin" ] && [ "${XCODE}" -ne 1 ]; then \
		xcode-select --install; \
	fi

homebrew: ## install homebrew
	@echo "Installing Homebrew..."
	if [ "${UNAME}" == "Darwin" ] && [ -z "${BREW}" ]; then \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi

git: ## install git
	@echo "Installing Git..."
	if [ "${UNAME}" == "Darwin" ] && [ ! -z "${BREW}" ]; then \
		brew install git; \
	elif [ "${ID}" == "ubuntu" ]; then \
		sudo apt install -y git; \
	elif [ "${ID}" == "fedora" ]; then \
		sudo dnf install -y git; \
	elif [ "${ID}" == "arch" ]; then \
		yes | sudo pacman -S git; \
	fi

python: ## install python
	@echo "Installing Python..."
	if [ "${UNAME}" == "Darwin" ] && [ -z "${PYTHON}" ]; then \
		brew install python; \
	elif [ "${ID}" == "ubuntu" ]; then \
		sudo apt install -y python3; \
	elif [ "${ID}" == "fedora" ]; then \
		sudo dnf install -y python3; \
	elif [ "${ID}" == "arch" ]; then \
		yes | sudo pacman -S python; \
	fi

pip: python ## install pip
	@echo "Installing Pip..."
	if [ "${UNAME}" == "Darwin" ] && [ -z "${PYTHON})" ]; then \
		brew install python@3.11; \
	elif [ "${ID}" == "ubuntu" ] && [ -z "${PIP}" ]; then \
		sudo apt install -y python3-pip; \
	elif [ "${ID}" == "fedora" ] && [ -z "${PIP}" ]; then \
		sudo dnf install -y python3-pip; \
	elif [ "${ID}" == "arch" ] && [ -z "${PIP}" ]; then \
		yes | sudo pacman -S python-pip; \
	fi \

nodejs: ## install nodejs
	@echo "Installing NodeJS..."
	if [ "${UNAME}" == "Darwin" ] && [ ! -z "${BREW}" ]; then \
		brew install node; \
	elif [ "${ID}" == "ubuntu" ]; then \
		sudo apt install -y nodejs; \
	elif [ "${ID}" == "fedora" ]; then \
		sudo dnf install -y nodejs; \
	elif [ "${ID}" == "arch" ]; then \
		yes | sudo pacman -S nodejs; \
	fi

just: ## install justfile
	@echo "Installing Justfile..."
	if [ "${UNAME}" == "Darwin" ]; then \
		brew install just; \
	elif [ "${ID}" == "ubuntu" ]; then \
		sudo apt install -y just; \
	elif [ "${ID}" == "fedora" ]; then \
		sudo dnf install -y just; \
	elif [ "${ID}" == "arch" ]; then \
		yes | sudo pacman -S just; \
	fi

# TODO: error handling (OS, binary, etc.)
snyk: ## install snyk
	@echo "Installing Snyk..."
	if [ "${UNAME}" == "Darwin" ]; then \
		brew tap snyk/tap; \
		brew install snyk; \
	else \
		curl https://static.snyk.io/cli/latest/snyk-macos -o snyk; \
		chmod +x ./snyk; \
		mv ./snyk /usr/local/bin/; \
	fi

install: sanity-check xcode homebrew git python pip nodejs just  ## install all dependencies

help: ## Show this help.
	@echo ''
	@echo 'Usage:'
	@echo '    ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "    ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  ${CYAN}%s${RESET}\n", substr($$1,4)} \
		}' $(MAKEFILE_LIST)
