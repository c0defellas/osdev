BOOTLOADERS = bootloaders/custom

all: build-loaders

build-loaders:
	$(foreach loader,$(BOOTLOADERS),cd $(loader);echo "Building $(loader)"; make;)
