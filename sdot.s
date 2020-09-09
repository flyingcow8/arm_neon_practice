#ifdef __aarch64__
    .text
    .align 5
    .global SdotTest
#ifndef __APPLE__
    .type SdotTest, %function
#endif

// void SdotTest(int8_t *a, int8_t *b, int *c)

SdotTest:
  sub sp, sp, #128
  st1 {v8.4s, v9.4s, v10.4s, v11.4s}, [sp], #64
  st1 {v12.4s, v13.4s, v14.4s, v15.4s}, [sp], #64

  dup v0.16b, wzr
  dup v1.16b, wzr
  dup v2.4s, wzr
  ld1 {v0.16b}, [x0]
  ld1 {v1.16b}, [x1]
  sdot v2.4s, v0.16b, v1.4b[0]
  st1 {v2.4s}, [x2]

  sub sp, sp, #128
  ld1 {v8.4s, v9.4s, v10.4s, v11.4s}, [sp], #64
  ld1 {v12.4s, v13.4s, v14.4s, v15.4s}, [sp], #64
  ret
#endif
