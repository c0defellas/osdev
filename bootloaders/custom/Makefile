.PHONY: build debug gdb

NASHURL = "https://github.com/NeowayLabs/nash/releases/download/v0.1.3-beta/nash"

all: deps build

deps: /usr/bin/nash

/usr/bin/nash:
	sudo wget -c $(NASHURL) -O /usr/bin/nash
	sudo chmod +x /usr/bin/nash
	nash -version

build:
	./make.sh

test:
	./make.sh test

debug:
	./make.sh debug-start-vm

gdb:
	./make.sh debug-gdb
