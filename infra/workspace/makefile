install = brew
objects = java docker vscode

# Applications to deploy, order is important
APPS = \
		awscli \
		aws-iam-authenticator \
		azure-cli \
		chef-workstation \
		chromedriver \
		docker \
		git \
		go \
		iterm2 \
		openjdk \
		maven \
		kubernetes-cli \
		newman \
		node \
		postman \
		serverless \
		springtoolsuite \
		terraform \
		vagrant \
		virtualbox \
		virtualbox-extension-pack \
		visual-studio-code

.DEFAULT_GOAL := help

prerequired:
	echo "
	echo "test that xcode is installed  xcode-select -p
	echo "for mac os xcode command, xcode-select --install"
	echo "brew list --versions > brew-versions.txt"

instal-brew:
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew-versions:
	brew list --versions > brew-versions.txt

clean:


.PHONY: install-all
install-all: $(foreach app,$(APPS),install-$(app)) ## Deploy all application to a given environment

.PHONY: deploy-%
install-%: instal-brew brew-versions ## install a single tool to a local workstation
	@-grep -Fq $* brew-versions.txt && ([ $$? -eq 0 ] && echo "$* installed success!") || brew install $*

.PHONY: help
help: ## Display this help. Thanks to https://suva.sh/posts/well-documented-makefiles/
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)