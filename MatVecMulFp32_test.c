#include <stdio.h>

void MatmulFp32Neon64_1xN(const float *a, const float *b, float *c, const float *bias, int act_type, int depth,
                          int col);

void RowMajor2ColMajor(float *src, int row, int col, float *dst) {
  for (int r = 0; r < row; ++r) {
    for (int c = 0; c < col; ++c) {
      dst[c * row + r] = src[r * col + c];
    }
  }
}

int main() {
  float a[1 * 13] = {4, 2, 2, 5, 4, 4, 0, 4, 0, 2, 2, 2, 2};
  float b[13 * 6] = {3, 5, 2, 3, 1, 3, 2, 3, 1, 0, 5, 4, 4, 0, 0, 1, 1, 2, 5, 1, 2, 2, 2, 5, 3, 2,
                     4, 1, 2, 3, 0, 4, 1, 2, 0, 4, 5, 4, 1, 5, 5, 1, 3, 5, 1, 0, 5, 4, 0, 3, 5, 2,
                     2, 0, 3, 4, 4, 1, 1, 0, 2, 1, 3, 1, 1, 3, 0, 0, 3, 1, 2, 4, 2, 4, 1, 3, 0, 5};
  float bb[13 * 6] = {0};
  float c[6] = {0};
  RowMajor2ColMajor(b, 13, 6, bb);
  MatmulFp32Neon64_1xN(a, bb, c, NULL, 0, 13, 6);
  for (int i = 0; i < 6; ++i) {
    printf("%f ", (float)c[i]);
  }
  printf("\n");
  return 0;
}