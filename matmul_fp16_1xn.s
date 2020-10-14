#ifdef __aarch64__
    .text
    .align 5
    .global Matmul1xNFp16Neon64
#ifndef __APPLE__
    .type Matmul1xNFp16Neon64, %function
#endif

// void Matmul1xNFp16Neon64(const float16_t *a, const float16_t *b, float16_t *c, int depth, int col)
// x0: a
// x1: b
// x2: c
// w3: depth
// w4: col

Matmul1xNFp16Neon64:
  sub sp, sp, #128
  st1 {v8.8h, v9.8h, v10.8h, v11.8h}, [sp], #64
  st1 {v12.8h, v13.8h, v14.8h, v15.8h}, [sp], #64

  mov w5, #2      // sizeof(float16)
  mul w8, w5, w3  // rhs depthx1 block stride
  mov w5, #4
  mul w13, w8, w5 // rhs depthx4 block stride 

Loop:
  mov x6, x0    // reload a ptr
  mov x7, x1    // reload b ptr
  mov w9, w3    // reload depth
  cmp w4, #4
  blt Loop1x1  

Loop1x4:
  dup v5.8h, wzr  
  dup v6.8h, wzr  
  dup v7.8h, wzr  
  dup v8.8h, wzr  
  dup v9.8h, wzr  
  dup v10.8h, wzr  
  dup v11.8h, wzr  
  dup v12.8h, wzr
  dup v13.8h, wzr

  add x10, x7, x8
  add x11, x10, x8
  add x12, x11, x8

Depth8_1x4:
  cmp w9, #8
  blt Depth1_1x4

  ld1 {v0.8h}, [x6], #16
  ld1 {v1.8h}, [x7], #16
  ld1 {v2.8h}, [x10], #16
  ld1 {v3.8h}, [x11], #16
  ld1 {v4.8h}, [x12], #16

  fmla v5.8h, v1.8h, v0.8h
  fmla v6.8h, v2.8h, v0.8h
  fmla v7.8h, v3.8h, v0.8h
  fmla v8.8h, v4.8h, v0.8h
  sub w9, w9, #8
  cbz w9, End1x4
  b Depth8_1x4

Depth1_1x4:
  ld1 {v0.h}[0], [x6], #2
  ld1 {v1.h}[0], [x7], #2
  ld1 {v1.h}[1], [x10], #2
  ld1 {v1.h}[2], [x11], #2
  ld1 {v1.h}[3], [x12], #2

  fmla v9.8h, v1.8h, v0.h[0]
  sub w9, w9, #1
  cbz w9, End1x4
  b Depth1_1x4

End1x4:
  faddp v10.8h, v5.8h, v6.8h
  faddp v11.8h, v7.8h, v8.8h
  faddp v12.8h, v10.8h, v11.8h
  faddp v13.8h, v12.8h, v12.8h
  fadd v13.8h, v13.8h, v9.8h

  st1 {v13.4h}, [x2], #8
  sub w4, w4, #4
  cbz w4, End
  add x1, x1, x13
  b Loop

Loop1x1:
  dup v2.8h, wzr
  dup v3.8h, wzr
  dup v4.8h, wzr
  dup v5.8h, wzr
  dup v6.8h, wzr

Depth8_1x1:
  cmp w9, #8
  blt Depth1_1x1

  ld1 {v0.8h}, [x6], #16
  ld1 {v1.8h}, [x7], #16

  fmla v2.8h, v1.8h, v0.8h
  sub w9, w9, #8
  cbz w9, End1x1
  b Depth8_1x1

Depth1_1x1:
  ld1 {v0.h}[0], [x6], #2
  ld1 {v1.h}[0], [x7], #2

  fmla v3.8h, v1.8h, v0.h[0]
  sub w9, w9, #1
  cbz w9, End1x1
  b Depth1_1x1

End1x1:
  faddp v4.8h, v2.8h, v2.8h  
  faddp v5.8h, v4.8h, v4.8h  
  faddp v6.8h, v5.8h, v5.8h  
  fadd v6.8h, v6.8h, v3.8h

  st1 {v6.h}[0], [x2], #2
  sub w4, w4, #1
  cbz w4, End
  add x1, x1, x8
  b Loop

End:
  sub sp, sp, #128
  ld1 {v8.8h, v9.8h, v10.8h, v11.8h}, [sp], #64
  ld1 {v12.8h, v13.8h, v14.8h, v15.8h}, [sp], #64
  ret
#endif
