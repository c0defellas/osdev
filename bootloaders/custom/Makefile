.PHONY: build debug gdb

NASHURL = "https://github.com/NeowayLabs/nash/releases/download/v0.1.3-beta/nash"
NASHBIN = ./vendor/bin/nash

all: deps build

deps: $(NASHBIN)

$(NASHBIN):
	mkdir -p ./vendor/bin
	wget -c $(NASHURL) -O $(NASHBIN)
	chmod +x $(NASHBIN)
	$(NASHBIN) -version

build:
	$(NASHBIN) ./make.sh

test:
	$(NASHBIN) ./make.sh test

debug:
	$(NASHBIN) ./make.sh debug-start-vm

gdb:
	$(NASHBIN) ./make.sh debug-gdb
