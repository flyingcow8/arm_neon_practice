#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#define UP_DIV(x, y) (((x) + (y) - (1)) / (y))
#define UP_ROUND(x, y) (((x) + (y) - (1)) / (y) * (y))

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

void Col4x4Major2RowMajor(int *src, int row_4, int cow_4, int *dst, int row, int cow) {
  int stride = sizeof(int8_t) * 4 * 4;
  for (int r = 0; r < row; ++r) {
    for (int c = 0; c < cow; ++c) {
      int sride_n = c / 4 * (row_4 / 4) + r / 4;
      int dst_idx = r * cow + c;
      dst[dst_idx] = src[stride * sride_n + c % 4 * 4 + r % 4];
    }
  }
}

void Row4x4Major2RowMajor(int *src, int row_4, int cow_4, int *dst, int row, int cow) {
  int stride = sizeof(int8_t) * 4 * 4;
  for (int r = 0; r < row; ++r) {
    for (int c = 0; c < cow; ++c) {
      int sride_n = c / 4 * (row_4 / 4) + r / 4;
      int dst_idx = r * cow + c;
      dst[dst_idx] = src[stride * sride_n + r % 4 * 4 + c % 4];
    }
  }
}

void MatmulInt8Neon64(const int8_t *a, const int8_t *b, int32_t *c, const int row4, const int col4, const int deep16);

void MatmulInt8RowMajorNeon64(const int8_t *a, const int8_t *b, int *c, int row4, int col4, int deep16, int row,
                              int col);

void test1() {
  // 4*16
  int8_t a[64] = {7, 5, 6, 10, 3, 10, 3, 10, 8, 3, 6,  0, 5, 7, 4, 3, 5, 7, 4, 7, 9, 2, 0, 1, 2, 1, 1, 9, 6, 10, 3, 1,
                  3, 7, 6, 1,  8, 8,  7, 10, 2, 0, 10, 5, 7, 1, 1, 9, 0, 0, 8, 5, 9, 6, 3, 9, 9, 7, 2, 7, 2, 9,  0, 4};
  // 16*4
  int8_t b[64] = {4, 1, 3, 3, 6, 8, 8, 6, 2, 0, 7, 8, 10, 5, 6, 2, 0, 2, 1, 2, 9, 3, 0, 10, 3, 5, 10, 6, 10, 6, 8, 7,
                  7, 3, 7, 6, 4, 5, 4, 8, 5, 4, 0, 9, 7,  4, 9, 7, 7, 2, 3, 9, 5, 9, 0, 2,  9, 0, 6,  9, 7,  2, 9, 0};
  int c[16] = {0};
  int8_t bb[64] = {0};
  RowMajor2Col16x4Major(b, 16, 4, bb, 16);
  MatmulInt8Neon64(a, bb, c, 4, 4, 16);
  for (int i = 0; i < 16; ++i) printf("%d ", c[i]);
  printf("\n");
}

void test2() {
  // 4*10
  int8_t a[40] = {6, 6, 3, 8, 10, 10, 1, 2,  8, 5, 10, 10, 5, 6, 8, 8, 5, 9, 4, 7,
                  0, 7, 1, 8, 9,  4,  5, 10, 0, 7, 6,  4,  4, 2, 8, 8, 4, 0, 1, 1};
  // 10*4
  int8_t b[40] = {10, 4, 6, 7, 8, 0, 4, 7, 0, 5, 10, 3, 10, 1,  7,  5, 3, 8, 2, 5,
                  8,  0, 1, 9, 9, 4, 9, 5, 8, 7, 8,  1, 3,  10, 10, 8, 5, 0, 6, 8};
  int c[16] = {0};
  int output[16] = {0};
  int deep_16 = UP_ROUND(10, 16);
  int8_t *a_align = (int8_t *)malloc(4 * deep_16);
  int8_t *b_align = (int8_t *)malloc(4 * deep_16);
  RowMajor2Row4x16Major(a, 4, 10, a_align, deep_16);
  RowMajor2Col16x4Major(b, 10, 4, b_align, deep_16);
  MatmulInt8Neon64(a_align, b_align, c, 4, 4, deep_16);
  Col4x4Major2RowMajor(c, 4, 4, output, 4, 4);
  for (int i = 0; i < 16; ++i) printf("%d ", output[i]);
  printf("\n");
}

void test3() {
  // 3*3
  int8_t a[9] = {1, 1, 1, 1, 1, 1, 1, 1, 1};
  // 3*3
  int8_t b[9] = {1, 1, 1, 1, 1, 1, 1, 1, 1};
  int c[16] = {0};
  int output[9] = {0};
  int deep_16 = UP_ROUND(3, 16);
  int8_t *a_align = (int8_t *)malloc(4 * deep_16);
  memset(a_align, 0, 4 * deep_16);
  int8_t *b_align = (int8_t *)malloc(4 * deep_16);
  memset(b_align, 0, 4 * deep_16);
  RowMajor2Row4x16Major(a, 3, 3, a_align, deep_16);
  RowMajor2Col16x4Major(b, 3, 3, b_align, deep_16);
  MatmulInt8Neon64(a_align, b_align, c, 4, 4, deep_16);

  // test start
  int c_test[16] = {0};
  Col4x4Major2RowMajor(c, 4, 4, c_test, 4, 4);
  for (int i = 0; i < 16; ++i) {
    printf("%d\t", c_test[i]);
    if ((i + 1) % 4 == 0) printf("\n");
  }
  printf("\n");
  // test end

  Col4x4Major2RowMajor(c, 4, 4, output, 3, 3);
  for (int i = 0; i < 9; ++i) printf("%d ", output[i]);
}

#define ROW 10
#define COL 15
#define DEPTH 10
#define ROW4 UP_ROUND(ROW, 4)
#define COL4 UP_ROUND(COL, 4)
#define DEPTH16 UP_ROUND(DEPTH, 16)

void test_r4x4() {
  int8_t a[ROW * DEPTH] = {1, 2, 3, 4};
  int8_t b[DEPTH * COL] = {1, 1, 1, 1};

  int c[ROW4 * COL4] = {0};
  int output[ROW * COL] = {0};
  int8_t *a_align = (int8_t *)malloc(ROW4 * DEPTH16);
  memset(a_align, 0, ROW4 * DEPTH16);
  int8_t *b_align = (int8_t *)malloc(COL4 * DEPTH16);
  memset(b_align, 0, COL4 * DEPTH16);
  RowMajor2Row4x16Major(a, ROW, DEPTH, a_align, DEPTH16);
  RowMajor2Col16x4Major(b, DEPTH, COL, b_align, DEPTH16);
  MatmulInt8Neon64(a_align, b_align, c, ROW4, COL4, DEPTH16);

  for (int i = 0; i < 16; ++i) printf("%d ", c[i]);
  printf("\n");

  // test start
  int c_test[ROW4 * COL4] = {0};
  Row4x4Major2RowMajor(c, ROW4, COL4, c_test, ROW4, COL4);
  for (int i = 0; i < ROW4 * COL4; ++i) {
    printf("%d\t", c_test[i]);
    if ((i + 1) % COL4 == 0) printf("\n");
  }
  printf("\n");
  // test end

  Row4x4Major2RowMajor(c, ROW4, COL4, output, ROW, COL);
  for (int i = 0; i < ROW * COL; ++i) printf("%d ", output[i]);
  printf("\n");
}

void test_row_major() {
  int8_t a[ROW * DEPTH] = {0, 7, 2, 3, 10, 4, 1,  8, 1,  3, 7, 4,  8, 9,  0, 9,  9, 4, 9,  9, 9, 0, 4,  4,  8,
                           3, 9, 2, 7, 4,  6, 10, 0, 10, 8, 6, 1,  1, 10, 0, 4,  9, 5, 10, 9, 6, 3, 10, 5,  10,
                           1, 2, 6, 9, 0,  1, 0,  4, 5,  2, 2, 10, 0, 5,  4, 10, 6, 5, 9,  4, 6, 4, 2,  10, 3,
                           0, 7, 4, 2, 1,  7, 10, 2, 2,  3, 2, 1,  8, 9,  8, 6,  6, 5, 7,  6, 9, 1, 0,  7,  6};
  int8_t b[DEPTH * COL] = {4, 10, 4, 9,  4,  6, 10, 6, 0,  6,  3,  10, 2,  1,  10, 3, 6,  9, 7, 10, 2, 5,  3,  1, 0,
                           1, 0,  8, 10, 5,  8, 0,  6, 10, 10, 5,  0,  9,  1,  9,  8, 0,  8, 2, 0,  6, 7,  3,  1, 3,
                           1, 0,  4, 8,  10, 2, 10, 6, 5,  7,  3,  5,  8,  0,  0,  6, 10, 4, 3, 9,  3, 8,  5,  8, 7,
                           8, 0,  5, 0,  7,  3, 4,  4, 4,  8,  9,  10, 3,  7,  1,  9, 0,  9, 1, 6,  8, 5,  8,  7, 5,
                           5, 9,  2, 2,  6,  3, 3,  9, 0,  1,  9,  5,  2,  10, 5,  6, 9,  9, 2, 8,  7, 10, 10, 1, 4,
                           6, 6,  0, 1,  10, 2, 8,  0, 3,  6,  10, 2,  10, 6,  4,  8, 9,  7, 8, 9,  8, 1,  6,  7, 2};

  int c[ROW4 * COL4] = {0};
  int output[ROW * COL] = {0};
  int8_t *a_align = (int8_t *)malloc(ROW4 * DEPTH16);
  memset(a_align, 0, ROW4 * DEPTH16);
  int8_t *b_align = (int8_t *)malloc(COL4 * DEPTH16);
  memset(b_align, 0, COL4 * DEPTH16);
  RowMajor2Row4x16Major(a, ROW, DEPTH, a_align, DEPTH16);
  RowMajor2Col16x4Major(b, DEPTH, COL, b_align, DEPTH16);
  MatmulInt8RowMajorNeon64(a_align, b_align, output, ROW4, COL4, DEPTH16, ROW, COL);

  for (int i = 0; i < ROW * COL; ++i) {
    printf("%d\t", output[i]);
    if ((i + 1) % COL == 0) printf("\n");
  }
  printf("\n");
}

int main() {
  test_row_major();
  return 0;
}