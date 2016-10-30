# Custom bootloader

This is an example for a custom bootloader.

It reads the second sector of booted disk at physical address 0x5000 and
look for a magic number (bytes 1337). If found, JUMP to the operating
system. Very straightforward.

Features:

- Enable [A20 address line](http://wiki.osdev.org/A20_Line)
- Load the OS from the second sector of disk;
- Enable a20 line;

It came with an example OS.

## How the building works

The script `make.sh` assembles the kernel, calculate the number of
disk sectors needed to store it in the disk and then pass this value
as a macro to the assembler when building the bootloader. The
bootloader needs to know the size of the kernel it must load, and this
value is passed in the `LOADNSECTORS` macro.

Basically, the steps below:

```sh
nasm -f bin kernel.asm -o kernel.bin
kernelsz <= getnsectors()
nasm -f bin -D "LOADNSECTORS="+$kernelsz bootloader.asm -o bootloader.bin
```

To create the raw disk image, the script uses only `dd` and a simplified
version of the
[fdisk](https://github.com/tiago4orion/enzo/tree/feat/fdisk/cmd/fdisk)
tool.

The script first creates a sparse file with size to accomodate the MBR
plus the sectors needed by the kernel.

```sh
dd "if=/dev/zero" "of=./disk.raw" "bs=512" "count="+$nsects
```

Where `$nsects` is `$kernelsz + 1`.

Then, it invokes the `fdisk` utility asking to create a MBR, putting
the bootloader in the first 446 bytes:

```sh
fdisk mbr -create -bootcode bootloader.bin disk.raw
```

And then copies the kernel to the second sector of disk using `dd` again.

In the end, the disk and memory should have the layout below:

         DISK LAYOUT                             MEMORY LAYOUT
                                               +-----------------+ -> 0x0500:0000 (kernel code seg)
                                               |    1 3 3 7      | -> magic number
                                               |   Kernel code   | -> 0x0500:0004 (kernel entry point)
                                               |                 |
                                               +-----------------+ -> 0x0500:(LOADNSECTORS * 512)
                                                        .
                                                        .
                                                        .
    +-------------------+  ^                   +-----------------+ -> 0x07c0:0000 (bootloader entry point)
    |   Bootloader      |  |                   |    Bootloader   |
    |                   |  |                   |                 |
    |    446 bytes      |  |                   |                 |
    |                   |  |                   |  Same as disk   |
    |                   |  |                   |                 |
    |                   |  | MBR (512 bytes)   |                 |
    |                   |  |                   |                 |
    |                   |  |                   |                 |
    |                   |  |                   |                 |
    |                   |  |                   |                 |
    +-------------------+  |                   |                 |
    |  empty partition  |  |                   |                 |
    |  table entries    |  |                   |                 |
    |  16x4 = 64 bytes  |  |                   |                 |
    +-------------------+  |                   |                 |
    |      0x55AA       |  |                   |     0x55AA      |
    +-------------------+  v                   +-----------------+ -> 0x07e0:0000 (bottom of stack)
    |     1 3 3 7       | -> magic number      |                 |
    |    Kernel code    |                      |    Stack of     |
    |                   |                      |  of bootloader  |
    +-------------------+                      |                 |
                                               |      64 kb      |
                                               |        .        |
                                               |        .        |
                                               |        .        |
                                               +-----------------+ -> 0x07e0:ffff (top of stack)

## Dependencies

- nasm
- coreutils >= 8.25
- qemu
- go

## Customizing

In `common.asm`, the macro `OS_SEGMENT` stores the address where the
operating system must be loaded.
In `booloader.asm`, the macros `OS_MAGIC` and `OS_SKIPHDR` store the
magic numbers and the number of bytes to skip at beginning of OS
(length of magic number for now).
