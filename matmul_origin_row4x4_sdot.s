#ifdef __aarch64__
    .text
    .align 5
    .global MatmulInt8Neon64
#ifndef __APPLE__
    .type MatmulInt8Neon64, %function
#endif



//                                      int8 RM 16x4 block
//                           /-----------------------------------------|
//                           |v4.b[0]          ...           v7.b[0]   |
//                           |  ...                            ...     |
//                           |v4.b[15]         ...           v7.b[15]  |
//                           \-----------------------------------------/
//    int8 LM 4x16 block
//  /---------------------\  /-----------------------------------------|
//  |v0.b[0] ... v0.b[15] |  |v16.4s    v17.4s     v18.4s    v19.4s    |
//  |v1.b[0] ... v1.b[15] |  |v20.4s    v21.4s     v22.4s    v23.4s    |
//  |v2.b[0] ... v2.b[15] |  |v24.4s    v25.4s     v26.4s    v27.4s    |
//  |v3.b[0] ... v3.b[15] |  |v28.4s    v29.4s     v30.4s    v31.4s    |
//  \---------------------/  \-----------------------------------------/
//                                  int32 accumulators 4x4 block
//
//
//void MatmulInt8Neon64(const int8_t *a, const int8_t *b, int32_t *c, const int row4, const int col4, const int deep16)
// x0: a, lm ptr
// x1: b, rm ptr
// x2: c, out ptr
// w3: row4
// w4: col4
// w5: deep16

MatmulInt8Neon64:
  sub sp, sp, #128
  st1 {v8.4s, v9.4s, v10.4s, v11.4s}, [sp], #64
  st1 {v12.4s, v13.4s, v14.4s, v15.4s}, [sp], #64

  mov w9, #0     // rm col offset
  mov w10, #0    // lm row offset
  mov w11, #0    // depth offset
  mov w7, #4    //sizeof(int8)*4
  mul w8, w5, w7  // the stride of lm/rm: sizeof(int8)*4*deep16
L1:
  cmp w9, w4      
  beq End1

  mov w10, #0    // reset lm row offset
  mov x12, x0   // reload lm ptr
L2:
  cmp w10, w3
  beq End2

  mov x16, x1   // reload rm ptr
  mov w13, w5   // reload depth
  dup v16.4s, wzr
  dup v17.4s, wzr
  dup v18.4s, wzr
  dup v19.4s, wzr
  dup v20.4s, wzr
  dup v21.4s, wzr
  dup v22.4s, wzr
  dup v23.4s, wzr
  dup v24.4s, wzr
  dup v25.4s, wzr
  dup v26.4s, wzr
  dup v27.4s, wzr
  dup v28.4s, wzr
  dup v29.4s, wzr
  dup v30.4s, wzr
  dup v31.4s, wzr
L3:
  cmp w13, #0 //depth
  beq End3

  ld1 {v0.16b}, [x12], #16
  ld1 {v1.16b}, [x12], #16
  ld1 {v2.16b}, [x12], #16
  ld1 {v3.16b}, [x12], #16
  ld1 {v4.16b}, [x16], #16
  ld1 {v5.16b}, [x16], #16
  ld1 {v6.16b}, [x16], #16
  ld1 {v7.16b}, [x16], #16

  sdot v16.4s, v4.16b, v0.16b
  sdot v17.4s, v5.16b, v0.16b
  sdot v18.4s, v6.16b, v0.16b
  sdot v19.4s, v7.16b, v0.16b
  sdot v20.4s, v4.16b, v1.16b
  sdot v21.4s, v5.16b, v1.16b
  sdot v22.4s, v6.16b, v1.16b
  sdot v23.4s, v7.16b, v1.16b
  sdot v24.4s, v4.16b, v2.16b
  sdot v25.4s, v5.16b, v2.16b
  sdot v26.4s, v6.16b, v2.16b
  sdot v27.4s, v7.16b, v2.16b
  sdot v28.4s, v4.16b, v3.16b
  sdot v29.4s, v5.16b, v3.16b
  sdot v30.4s, v6.16b, v3.16b
  sdot v31.4s, v7.16b, v3.16b
  
  subs w13, w13, #16  // depth + 16
  b L3

End3:
  addp v16.4s, v16.4s, v17.4s
  addp v18.4s, v18.4s, v19.4s
  addp v20.4s, v20.4s, v21.4s
  addp v22.4s, v22.4s, v23.4s
  addp v24.4s, v24.4s, v25.4s
  addp v26.4s, v26.4s, v27.4s
  addp v28.4s, v28.4s, v29.4s
  addp v30.4s, v30.4s, v31.4s

  addp v16.4s, v16.4s, v18.4s
  addp v17.4s, v20.4s, v22.4s
  addp v18.4s, v24.4s, v26.4s
  addp v19.4s, v28.4s, v30.4s

  st1 {v16.4s}, [x2], #16
  st1 {v17.4s}, [x2], #16
  st1 {v18.4s}, [x2], #16
  st1 {v19.4s}, [x2], #16
  add w10, w10, #4    // lm row offset + 4
  b L2

End2:
  add w9, w9, #4      // rm col offset + 4
  add x1, x1, x8     // rm ptr + stride
  b L1

End1:
  sub sp, sp, #128
  ld1 {v8.4s, v9.4s, v10.4s, v11.4s}, [sp], #64
  ld1 {v12.4s, v13.4s, v14.4s, v15.4s}, [sp], #64
  ret
#endif
