# Elfos-dzx1

> [!NOTE]
>This repository has a submodule for the include files needed to build it. You can have these pulled automatically if you add the  --
recurse option to your git clone command.

This is a utility for Elf/OS that decompresses ZX1 files. The ZX1 compression algorithm, by Einar Saukas is designed to be small and fast on 8-bit processors and so is well-suited for the 1802 and Elf/OS.

At this time, there is no native 1802 compressor since the algorithm for optimal compression is a little complex and resource-intensive, however this will decode compressed files created by the C compressor here:

https://github.com/einar-saukas/ZX1  
