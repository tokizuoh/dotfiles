.PHONY: all
all:
	./bootstrap.sh

.PHONY: update-vscode-extensions
update-vscode-extensions:
	./update-extensions.sh
