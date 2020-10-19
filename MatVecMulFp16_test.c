#include <arm_neon.h>
#include <stdio.h>

void MatmulFp16Neon64_1xN(const float16_t *a, const float16_t *b, float16_t *c, const float16_t *bias, int act_type, int depth, int col);

void RowMajor2ColMajor(float16_t *src, int row, int col, float16_t *dst) {
  for (int r = 0; r < row; ++r) {
    for (int c = 0; c < col; ++c) {
      dst[c * row + r] = src[r * col + c];
    }
  }
}

int main() {
  float16_t a[1 * 10] = {4, 3, 1, 0, 3, 1, 5, 2, 1, 1};
  float16_t b[10 * 6] = {4, 2, 0, 3, 5, 4, 
                        2, 4, 0, 0, 3, 1,
                        3, 3, 5, 4, 5, 0, 
                        4, 1, 1, 4, 3, 5,
                        4, 2, 1, 3, 1, 0, 
                        0, 4, 1, 0, 0, 2, 
                        2, 2, 4, 3, 2, 1, 
                        3, 2, 5, 4, 4, 4,
                        1, 1, 1, 1, 1, 1,
                        1, 1, 1, 1, 1, 1};
  float16_t bb[60] = {0};
  float16_t c[6] = {0};
  RowMajor2ColMajor(b, 10, 6, bb);
  MatmulFp16Neon64_1xN(a, bb, c, NULL, 0, 10, 6);
  for (int i = 0; i < 6; ++i) {
    printf("%f ", (float)c[i]);
  }
  printf("\n");
  return 0;
}