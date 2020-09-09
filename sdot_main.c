// gcc -march=armv8.2-a+dotprod sdot_main.c sdot.s

#include <stdint.h>
#include <stdio.h>

void SdotTest(int8_t *a, int8_t *b, int *c);

int main() {
  int8_t a[16] = {1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4};
  int8_t b[16] = {1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4};
  int c[4] = {0, 0, 0, 0};
  SdotTest(a, b, c);
  for (int i = 0; i < 4; ++i) printf("%d ", c[i]); printf("\n");
  return 0;
}