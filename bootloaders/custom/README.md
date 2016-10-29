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

## Dependencies

- nasm
- coreutils >= 8.25

## Customizing

In `common.asm`, the macro `OS_SEGMENT` stores the address where the
operating system must be loaded.
In `booloader.asm`, the macros `OS_MAGIC` and `OS_SKIPHDR` store the
magic numbers and the number of bytes to skip at beginning of OS
(length of magic number for now).
