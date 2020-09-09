#include <stdio.h>
#include <stdint.h>

int main() {
  int a[4] = {1, 2, 3, 4};
  int b[4] = {0};
  asm(
    "ld1 {v0.4s}, [%[a]]\n"
    "st1 {v0.s[0], v0.s[1]}, [%[b]]\n"
    :
    : [a] "r"(a), [b] "r"(b)
    :);
  for (int i = 0; i < 4; ++i) printf("%d ", b[i]);printf("\n");
  return 0;
}