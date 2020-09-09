#include <stddef.h>
#include <stdint.h>
#include <limits.h>

const uint64_t dSignMask = 1ull << 63;
const uint64_t dExponentMask = 0x7ffull << 52;
const uint64_t dFractionMask = (1ull << 52) - 1;
const int dExponentBias = 1022;
const int dMantissaBits = 52;
const int dInfiniteExponent = 0x7ff;
const double dNormalizer = 0x1p54;
const int dNormalizerBias = 54;
const int iMantissaBits = 31;

void QuantizeMultiplier(double double_multiplier, int *quantized_multiplier, int *shift) {
  if (quantized_multiplier == NULL || shift == NULL) {
    return;
  }
  // we split a floating number into two parts: exponent and fraction
  // since fraction is stored as int32, only 31 bits of mantissa is remained
  union {
    double d;
    uint64_t ul;
  } dul;
  dul.d = double_multiplier;
  if (!(dul.ul & (~dSignMask))) {
    // multiplier is 0
    *quantized_multiplier = 0;
    *shift = 0;
    return;
  }
  int exponent = (int)((dul.ul & dExponentMask) >> dMantissaBits);
  if (exponent == dInfiniteExponent) {
    // multiplier is inf or NaN
    *shift = 0;
    if (!(dul.ul & dFractionMask)) {
      // inf
      *quantized_multiplier = (dul.ul & dSignMask) ? INT_MIN : INT_MAX;
    } else {
      // NaN
      *quantized_multiplier = 0;
    }
    return;
  }
  if (exponent == 0) {
    // multiplier is a subnormal number
    dul.d *= dNormalizer;
    exponent = (int)((dul.ul & dExponentMask) >> dMantissaBits);
    *shift = exponent - dExponentBias - dNormalizerBias;
  } else {
    *shift = exponent - dExponentBias;
  }
  uint64_t fraction = dul.ul & dFractionMask;
  fraction += (1ull << dMantissaBits);
  uint64_t rounded = ((fraction >> (dMantissaBits - iMantissaBits)) + 1ull) >> 1;
  // we get 31 rounded bits now
  if (rounded == (1ull << iMantissaBits)) {
    // rounding may cause a carry
    rounded >>= 1;
    ++*shift;
  }
  *quantized_multiplier = (dul.ul & dSignMask) ? (-(int32_t)(rounded)) : (int32_t)(rounded);
}