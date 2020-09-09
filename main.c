#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>

#define UP_DIV(x, y) (((x) + (y) - (1)) / (y))
#define UP_ROUND(x, y) (((x) + (y) - (1)) / (y) * (y))

#define ROW 4
#define COL 4
#define DEPTH 1
#define ROW4 UP_ROUND(ROW, 4)
#define COL4 UP_ROUND(COL, 4)
#define DEPTH16 UP_ROUND(DEPTH, 16)

void MatmulInt8Neon64(const int8_t *a, const int8_t *b, int8_t *dst, int row4, int col4, int deep16, const int *a_sums,
                      const int *bias, int act_min, int act_max, int out_zp, int multiplier, int left_shift,
                      int right_shift);

void QuantizeMultiplier(double double_multiplier, int *quantized_multiplier, int *shift);

void RowMajor2Row4x16Major(int8_t *src, int row, int col, int8_t *dst, int col_16) {
  int stride = sizeof(int8_t) * 16 * 4;
  for (int r = 0; r < row; ++r) {
    for (int c = 0; c < col; ++c) {
      int stride_n = r / 4 * (col_16 / 16) + c / 16;
      int src_idx = r * col + c;
      dst[stride * stride_n + r % 4 * 16 + c % 16] = src[src_idx];
    }
  }
}

void RowMajor2Col16x4Major(int8_t *src, int row, int col, int8_t *dst, int row_16) {
  int stride = sizeof(int8_t) * 16 * 4;
  for (int r = 0; r < row; ++r) {
    for (int c = 0; c < col; ++c) {
      int stride_n = c / 4 * (row_16 / 16) + r / 16;
      int src_idx = r * col + c;
      dst[stride * stride_n + c % 4 * 16 + r % 16] = src[src_idx];
    }
  }
}

void RowMajor2Asums(int8_t *a, int row, int col, int b_zp, int *dst) {
  for (int r = 0; r < row; ++r) {
    for (int c = 0; c < col; ++c) {
      int src_idx = r * col + c;
      dst[r] += a[src_idx];
    }
    dst[r] *= b_zp;
  }
}

void RowMajor2Bbias(int8_t *b, int row, int col, int a_zp, int b_zp, int *bias, int *dst) {
  for (int c = 0; c < col; ++c) {
    for (int r = 0; r < row; ++r) {
      int src_idx = r * col + c;
      dst[c] += b[src_idx];
    }
    dst[c] = row * a_zp * b_zp - a_zp * dst[c];
    if (bias) {
      dst[c] += bias[c];
    }
  }
}

void Row4x4Major2RowMajor(int8_t *src, int row4, int8_t *dst, int row, int cow) {
  int stride = sizeof(int8_t) * 4 * 4;
  for (int r = 0; r < row; ++r) {
    for (int c = 0; c < cow; ++c) {
      int sride_n = c / 4 * (row4 / 4) + r / 4;
      int dst_idx = r * cow + c;
      dst[dst_idx] = src[stride * sride_n + r % 4 * 4 + c % 4];
    }
  }
}

void test_r4x4() {
  int8_t a[ROW * DEPTH] = {1, 2, 3, 4};
  int8_t b[DEPTH * COL] = {1, 1, 1, 1};
  int a_sums[ROW4] = {0};
  int b_sums[COL4] = {0};

  int8_t c[ROW4 * COL4] = {0};
  int8_t output[ROW * COL] = {0};
  int8_t *a_align = (int8_t *)malloc(ROW4 * DEPTH16);
  memset(a_align, 0, ROW4 * DEPTH16);
  int8_t *b_align = (int8_t *)malloc(COL4 * DEPTH16);
  memset(b_align, 0, COL4 * DEPTH16);

  RowMajor2Row4x16Major(a, ROW, DEPTH, a_align, DEPTH16);
  RowMajor2Col16x4Major(b, DEPTH, COL, b_align, DEPTH16);
  RowMajor2Asums(a, ROW, DEPTH, 0, a_sums);
  RowMajor2Bbias(b, DEPTH, COL, 0, 0, NULL, b_sums);
  int multiplier;
  int shift;
  QuantizeMultiplier(1.0f, &multiplier, &shift);
  MatmulInt8Neon64(a_align, b_align, c, ROW4, COL4, DEPTH16, a_sums, b_sums, INT_MIN, INT_MAX, 0, multiplier, 0, 0);

  // test start
  int8_t c_test[ROW4 * COL4] = {0};
  Row4x4Major2RowMajor(c, ROW4, COL4, c_test, ROW4, COL4);
  for (int i = 0; i < ROW4 * COL4; ++i) {
    printf("%d\t", output[i]);
    if ((i + 1) % COL4 == 0) printf("\n");
  }
  printf("\n");
  return;

  Row4x4Major2RowMajor(c, ROW4, COL4, output, ROW, COL);
  for (int i = 0; i < ROW * COL; ++i) printf("%d ", output[i]);
  printf("\n");
}

int main() {
  test();
  return 0;
}