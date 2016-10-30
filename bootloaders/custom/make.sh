#!/usr/bin/env nash

IFS = ()

# working directory
wdir <= pwd | tr -d "\n"

dd --version

IFS            = ()
ASFLAGS        = ("-fbin")
BOOTLOADER_SRC = "bootloader.asm"
KERNEL_SRC     = "kernel.asm"
KERNEL_BIN     = "kernel.bin"
BOOTLOADER_BIN = "bootloader.bin"
DISKIMG        = "disk.raw"
GOPATH         = $wdir+"/vendor"

setenv GOPATH

rm -f $DISKIMG $KERNEL_BIN $BOOTLOADER_BIN
-mkdir -p $GOPATH
-test -f $GOPATH+"/bin/fdisk"

if $status != "0" {
	-go get -v github.com/tiago4orion/enzo

	chdir($GOPATH+"/src/github.com/tiago4orion/enzo")

	git checkout feat/fdisk
	make

	chdir($wdir)
}

# getnsectors returns the amount of block sectors needed to
# fit the kernel into
fn getnsectors() {
	sectsz = "0"

	kernelsz <= wc -c $KERNEL_BIN | cut -d " " -f1 | tr -d "\n"
	sectsz   <= -expr $kernelsz "/" 512 | tr -d "\n"

	if $sectsz == "0" {
		sectsz <= expr $sectsz "+" 1 | tr -d "\n"
	} else if $sectsz == "" {
		sectsz <= expr 0 "+" 1 | tr -d "\n"
	}

	return $sectsz
}

fn buildKernel() {
	nasm $ASFLAGS -o $KERNEL_BIN $KERNEL_SRC
}

fn buildLoader() {
	-test -f $KERNEL_BIN

	if $status != "0" {
		echo "error: Kernel must be compiled before the bootloader"

		return
	}

	sectsz <= getnsectors()

	nasm $ASFLAGS "-DLOADNSECTORS="+$sectsz -o $BOOTLOADER_BIN $BOOTLOADER_SRC
}

fn makeDisk() {
	rm -f disk.raw

	sectsz <= getnsectors()

	# add a sector to put mbr
	sectsz <= expr $sectsz "+" 1 | tr -d "\n"

	dd "if=/dev/zero" "of="+$DISKIMG "bs=512" "count="+$sectsz

	# workaround to force use of our fdisk
	p    = $PATH
	PATH = $GOPATH+"/bin"

	setenv PATH

	fdisk mbr -create -bootcode $BOOTLOADER_BIN $DISKIMG

	PATH = $p

	setenv PATH

	codesz    <= wc -c $KERNEL_BIN | cut -d " " -f1 | tr -d "\n"
	remaining <= -expr 512 "-" $codesz
	seek      <= expr 512 "+" $codesz

	dd "if="+$KERNEL_BIN "of="+$DISKIMG "oflag=seek_bytes" "seek=512" "bs="+$codesz "count=1"
}

buildKernel()
buildLoader()
makeDisk()

echo "Kernel successfully built"

if len($ARGS) == "2" {
	arg = $ARGS[1]

	if $arg == "test" {
		qemu-system-x86_64 -hda $DISKIMG -m 256
	} else if $arg == "debug-start-vm" {
		qemu-system-x86_64 -hda $DISKIMG -m 256 -s -S
	} else if $arg == "debug-gdb" {
		(
			gdb -ex "target remote localhost:1234"
							-ex "set architecture i8086"
							-ex "set disassembly-flavor intel"
							-ex "layout asm"
							-ex "layout regs"
							-ex "break *0x7c00"
							-ex "break *0x7d5c"
							-ex "continue"
		)
	}
}
