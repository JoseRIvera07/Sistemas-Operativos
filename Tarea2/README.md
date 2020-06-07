#### CE-4303
#### Principios de Sistemas Operativos
#### Tarea 2 / Sanabria E. - García P. & Herrera A.
#### IIS - 2019

# EAT APPLES (BOOTEABLE)

## Abstract

#
## Dependecies Installation

Run the command:

> $ make install

#
## Fast Options

### Fast Compile 

Run the command:

> $ make

### Fast Emulation

Run the command:

> $ make qemu

### Fast Bootable device creation

Run the command:

> $ make live-usb

#
## Step-by-Step Compile

### Generate Binary

Run the command:

> $ nasm -o snake -fbin loader.asm

#### Test Binary

Run the command:

> $ sudo qemu-system-i386 snake

### Make the img file

Run the command:

> $ dd if=/dev/zero of=floppy.img bs=512 count=2880
> $ dd if=test.bin of=floppy.img