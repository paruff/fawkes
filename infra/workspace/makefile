install = brew
objects = java docker vscode
all: $(objects)

# These files compile via implicit rules
java: 
	brew install $@

prerequired:
	echo "
	echo "test that xcode is installed  xcode-select -p
	echo "for mac os xcode command, xcode-select --install"

brew:
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

clean:
	