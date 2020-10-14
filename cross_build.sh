#!/bin/bash

aarch64-linux-android29-clang -g -static -march=armv8.2-a+fp16 matmul_fp16_test.c matmul_fp16_1xn.s