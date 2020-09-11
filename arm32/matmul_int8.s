#ifdef __arm__
#ifndef __aarch64__

.text
.align 5
.global MatmulInt8Neon32
#ifndef __APPLE__
.type MatmulInt8Neon32, %function
#endif


  //                                              int8 RHS 16x2 block
  //                                              /-----------------|
  //                                              |d8.b[0]  d10.b[0]|
  //                                              |  ...      ...   |
  //                                              |d8.b[7]  d10.b[7]|
  //                                              |d9.b[0]  d11.b[0]|
  //                                              |  ...      ...   |
  //                                              |d9.b[7]  d11.b[7]|
  //                                              \-----------------/
  //    int8 LHS 4x16 block
  //  /---------------------------------------\   /------------------|
  //  |d0.b[0] ... d0.b[7] d1.b[0] ... d1.b[7]|   |  q6(q14) q7(q2) |
  //  |d2.b[0] ... d2.b[7] d3.b[0] ... d3.b[7]|   |  q8(q15) q9(q3) |
  //  (Reload d0, d1, d2, d3)
  //  |d0.b[0] ... d0.b[7] d1.b[0] ... d1.b[7]|   |  q10(q14) q11(q2) |
  //  |d2.b[0] ... d2.b[7] d3.b[0] ... d3.b[7]|   |  q12(q15) q13(q3) |
  //  \---------------------------------------/   \-----------------/
  //                                         128-bit accumulators 4x2 block
  //
//void MatmulInt8Neon32(const int8_t *a, const int8_t *b, int8_t *dst, int row, int col, int deep16, 
//                      const int *input_sums, const int *weight_bias, int act_min, int act_max, int out_zp,
//                      int multiplier, int left_shift, int right_shift, int stride);
// #0: a, #4: b, #8: dst, #12: row
// #16: col, #20: deep16, #24: input_sums, #28: weight_bias, #32: act_min, #36: act_max, #40: out_zp
// #28: multiplier, #32: left_shift, #36: right_shift, #40: stride

MatmulInt8Neon32:
  push {r0-r3}
  push {r4-r11, lr}
  vpush {q4-q7}
  add sp, sp, #100    //36+64

  ldr r2, [sp, #8]      // dst ptr
  ldr r4, [sp, #16]     // col
  mov r7, #2
  ldr r8, [sp, #20]     // deep16
  mul r9, r7, r8        // the sride of b

L1:
  cmp r4, #0    // if at the end of col
  ble End1

  ldr r0, [sp]        // reload a ptr
  ldr r3, [sp, #12]   // reset row counter
  ldr r6, [sp, #24]    // reload intpu_sums ptr
L2:
  cmp r3, #0    // if at the end of row
  ble End2

  ldr r1, [sp, #4]    // reload b ptr
  ldr r7, [sp, #28]   // reload weight_bias ptr
  ldr r5, [sp, #20]   // reset deep16
  vmov.i32 q6, #0
  vmov.i32 q7, #0
  vmov.i32 q8, #0
  vmov.i32 q9, #0
  vmov.i32 q10, #0
  vmov.i32 q11, #0
  vmov.i32 q12, #0
  vmov.i32 q13, #0
L3:
  cmp r5, #0
  beq End3

  vld1.8 {d0, d1, d2, d3}, [r0]!
  vld1.8 {d8, d9, d10, d11}, [r1]!
  vmull.s8 q14, d0, d8
  vmull.s8 q2, d0, d10
  vmull.s8 q15, d2, d8
  vmull.s8 q3, d2, d10
  vmlal.s8 q14, d1, d9
  vmlal.s8 q2, d1, d11
  vmlal.s8 q15, d3, d9
  vmlal.s8 q3, d3, d11

  vpadal.s16 q6, q14
  vpadal.s16 q7, q2
  vpadal.s16 q8, q15
  vpadal.s16 q9, q3

  vld1.8 {d0, d1, d2, d3}, [r0]!
  vmull.s8 q14, d0, d8
  vmull.s8 q2, d0, d10
  vmull.s8 q15, d2, d8
  vmull.s8 q3, d2, d10
  vmlal.s8 q14, d1, d9
  vmlal.s8 q2, d1, d11
  vmlal.s8 q15, d3, d9
  vmlal.s8 q3, d3, d11

  vpadal.s16 q10, q14
  vpadal.s16 q11, q2
  vpadal.s16 q12, q15
  vpadal.s16 q13, q3
  sub r5, r5, #16  // deep16 -= 16
  b L3

End3:
  vpadd.i32 d0, d12, d13
  vpadd.i32 d1, d14, d15
  vpadd.i32 d2, d16, d17
  vpadd.i32 d3, d18, d19
  vpadd.i32 d4, d20, d21
  vpadd.i32 d5, d22, d23
  vpadd.i32 d6, d24, d25
  vpadd.i32 d7, d26, d27

  vpadd.i32 d28, d0, d1
  vpadd.i32 d29, d2, d3
  vpadd.i32 d30, d4, d5
  vpadd.i32 d31, d6, d7

  //...

  // Cast-and-saturate from int32 to int16
  vqmovn.s32 d28, q14
  vqmovn.s32 d29, q15

  // Cast-and-saturate from int16 to int8
  vqmovn.s16 d30, q14

  vst1.8 {d30}, [r2]!
  sub r3, r3, #4   // a row counter -= 4
  b L2

End2:
  sub r4, r4, #2  // b col counter -= 2
  add r1, r1, r9  // b ptr + stride
  str r1, [sp, #4]
  b L1

End1:
  sub sp, sp, #100
  vpop {q4-q7}
  pop {r4-r11, pc}
  pop {r0-r3}
#endif
#endif
