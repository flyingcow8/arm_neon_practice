#ifdef __aarch64__
    .text
    .align 5
    .global MatmulInt8RowMajorNeon64
#ifndef __APPLE__
    .type MatmulInt8RowMajorNeon64, %function
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
//void MatmulInt8RowMajorNeon64(const int8_t *a, const int8_t *b, int *c, int row4, int col4, int deep16, int row, int col)
// x0: a, lm ptr
// x1: b, rm ptr
// x2: c, out ptr
// w3: row4
// w4: col4
// w5: deep16
// w6: row
// w7: col

MatmulInt8RowMajorNeon64:
  sub sp, sp, #128
  st1 {v8.4s, v9.4s, v10.4s, v11.4s}, [sp], #64
  st1 {v12.4s, v13.4s, v14.4s, v15.4s}, [sp], #64

  mov w12, #4       //sizeof(int8)*4
  mul w8, w5, w12   // the stride of lm/rm: sizeof(int8)*4*deep16
  mul w9, w7, w12   //the row sride of output: sizeof(int) * col
  mov x17, x2 //for test
  mov x15, x2
L1:
  cmp w4, #0      // if at the end of col4
  beq End1

  mov w10, w3     // reset lm row4 counter
  mov w11, w6     // reset lm row counter
  mov x12, x0     // reload lm ptr
L2:
  cmp w10, #0   // if at the end of row4
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

  smull    v8.8h,  v4.8b,  v0.8b
  smull    v9.8h,  v5.8b,  v0.8b
  smull    v10.8h,  v6.8b,  v0.8b
  smull    v11.8h,  v7.8b,  v0.8b
  smull    v12.8h,  v4.8b,  v1.8b
  smull    v13.8h,  v5.8b,  v1.8b
  smull    v14.8h,  v6.8b,  v1.8b
  smull    v15.8h,  v7.8b,  v1.8b

  smlal2    v8.8h,  v4.16b,  v0.16b
  smlal2    v9.8h,  v5.16b,  v0.16b
  smlal2    v10.8h,  v6.16b,  v0.16b
  smlal2    v11.8h,  v7.16b,  v0.16b
  smlal2    v12.8h,  v4.16b,  v1.16b
  smlal2    v13.8h,  v5.16b,  v1.16b
  smlal2    v14.8h,  v6.16b,  v1.16b
  smlal2    v15.8h,  v7.16b,  v1.16b

  sadalp  v16.4s, v8.8h
  sadalp  v17.4s, v9.8h
  sadalp  v18.4s, v10.8h
  sadalp  v19.4s, v11.8h
  sadalp  v20.4s, v12.8h
  sadalp  v21.4s, v13.8h
  sadalp  v22.4s, v14.8h
  sadalp  v23.4s, v15.8h

  smull    v8.8h,  v4.8b,  v2.8b
  smull    v9.8h,  v5.8b,  v2.8b
  smull    v10.8h,  v6.8b,  v2.8b
  smull    v11.8h,  v7.8b,  v2.8b
  smull    v12.8h,  v4.8b,  v3.8b
  smull    v13.8h,  v5.8b,  v3.8b
  smull    v14.8h,  v6.8b,  v3.8b
  smull    v15.8h,  v7.8b,  v3.8b

  smlal2    v8.8h,  v4.16b,  v2.16b
  smlal2    v9.8h,  v5.16b,  v2.16b
  smlal2    v10.8h,  v6.16b,  v2.16b
  smlal2    v11.8h,  v7.16b,  v2.16b
  smlal2    v12.8h,  v4.16b,  v3.16b
  smlal2    v13.8h,  v5.16b,  v3.16b
  smlal2    v14.8h,  v6.16b,  v3.16b
  smlal2    v15.8h,  v7.16b,  v3.16b

  sadalp  v24.4s, v8.8h
  sadalp  v25.4s, v9.8h
  sadalp  v26.4s, v10.8h
  sadalp  v27.4s, v11.8h
  sadalp  v28.4s, v12.8h
  sadalp  v29.4s, v13.8h
  sadalp  v30.4s, v14.8h
  sadalp  v31.4s, v15.8h
  subs w13, w13, #16    // deep16 - 16
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

  cmp w11, #4
  blt Write
  cmp w7, #4
  blt Write

  st1 {v16.4s}, [x2], x9
  st1 {v17.4s}, [x2], x9
  st1 {v18.4s}, [x2], x9
  st1 {v19.4s}, [x2], x9
  b Endwrite
  
Write:
  cmp w7, #4
  beq WriteCol4
  cmp w7, #3
  beq WriteCol3
  cmp w7, #2
  beq WriteCol2
  cmp w7, #1
  beq WriteCol1

WriteCol4:
  st1 {v16.4s}, [x2], x9
  cmp w11, #1
  beq Endwrite
  st1 {v17.4s}, [x2], x9
  cmp w11, #2
  beq Endwrite
  st1 {v18.4s}, [x2], x9
  cmp w11, #3
  beq Endwrite
  st1 {v19.4s}, [x2], x9
  b Endwrite

WriteCol3:
  mov x14, x2
  st1 {v16.s}[0], [x14], #4
  st1 {v16.s}[1], [x14], #4
  st1 {v16.s}[2], [x14], #4
  add x2, x2, x9
  cmp w11, #1
  beq Endwrite
  mov x14, x2
  st1 {v17.s}[0], [x14], #4
  st1 {v17.s}[1], [x14], #4
  st1 {v17.s}[2], [x14], #4
  add x2, x2, x9
  cmp w11, #2
  beq Endwrite
  mov x14, x2
  st1 {v18.s}[0], [x14], #4
  st1 {v18.s}[1], [x14], #4
  st1 {v18.s}[2], [x14], #4
  add x2, x2, x9
  cmp w11, #3
  beq Endwrite
  mov x14, x2
  st1 {v19.s}[0], [x14], #4
  st1 {v19.s}[1], [x14], #4
  st1 {v19.s}[2], [x14], #4
  add x2, x2, x9
  b Endwrite

WriteCol2:
  mov x14, x2
  st1 {v16.s}[0], [x14], #4
  st1 {v16.s}[1], [x14], #4
  add x2, x2, x9
  cmp w11, #1
  beq Endwrite
  mov x14, x2
  st1 {v17.s}[0], [x14], #4
  st1 {v17.s}[1], [x14], #4
  add x2, x2, x9
  cmp w11, #2
  beq Endwrite
  mov x14, x2
  st1 {v18.s}[0], [x14], #4
  st1 {v18.s}[1], [x14], #4
  add x2, x2, x9
  cmp w11, #3
  beq Endwrite
  mov x14, x2
  st1 {v19.s}[0], [x14], #4
  st1 {v19.s}[1], [x14], #4
  add x2, x2, x9
  b Endwrite

WriteCol1:
  st1 {v16.s}[0], [x2], x9
  cmp w11, #1
  beq Endwrite
  st1 {v17.s}[0], [x2], x9
  cmp w11, #2
  beq Endwrite
  st1 {v18.s}[0], [x2], x9
  cmp w11, #3
  beq Endwrite
  st1 {v19.s}[0], [x2], x9
  b Endwrite

Endwrite:  
  sub w10, w10, #4    // lm row4 counter - 4
  sub w11, w11, #4    // lm row counter - 4
  b L2

End2:
  sub w4, w4, #4      // rm col4 counter - 4
  sub w7, w7, #4      // rm col counter - 4
  add x1, x1, x8      // rm ptr + stride
  add x15, x15, #16
  mov x2, x15
  b L1

End1:
  sub sp, sp, #128
  ld1 {v8.4s, v9.4s, v10.4s, v11.4s}, [sp], #64
  ld1 {v12.4s, v13.4s, v14.4s, v15.4s}, [sp], #64
  ret
#endif
