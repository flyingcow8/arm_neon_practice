#!/bin/bash

armv7a-linux-androideabi21-clang -static -mcpu=cortex-a15 -mfpu=neon -mfloat-abi=softfp -g main.c matmul_int8.s
