# arm_neon_practice
Assembly code using neon vector registers for arm64 and arm32 platforms

## Launch aarch64 vm with QEMU

https://futurewei-cloud.github.io/ARM-Datacenter/qemu/how-to-launch-aarch64-vm/

## Share files between vm and host

https://www.cnblogs.com/pengdonglin137/p/6431234.html

## Build and run ARM 64-bit ELF

Use gcc in ubuntu aarch64, just like doing in ubuntu x86

## Build and run ARM 32-bit ELF

Build  in x86 host, using gcc-arm-none-eabi or android-ndk toolchains. For example:

```
*/android-ndk-r21b/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang -static -mcpu=cortex-a15 -mfpu=neon -mfloat-abi=softfp a.c
```

How to run arm 32-bit  app on arm 64-bit platform?

https://askubuntu.com/questions/1090351/can-i-run-an-arm32-bit-app-on-an-arm64bit-platform-which-is-running-ubuntu-16-04

Do the instructions in the above post in ubuntu aarch64 vm. Then you can run arm 32-bit app on aarch64 platform! 

 

