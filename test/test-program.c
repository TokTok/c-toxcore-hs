#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "crypto_core.h"

int main(void)
{
  printf("%u\n", random_u32());
  printf("%lu\n", random_u64());

  const uint8_t pk[32] = { 0, 1, 2, 3, 4 };
  const uint8_t sk[32] = { 0, 4, 3, 2, 1 };
  uint8_t ck[32] = { 0 };
  encrypt_precompute(pk, sk, ck);

  uint8_t nonce[24] = { 0 };
  random_nonce(nonce);

  const char plain[] = "hello world";
  char encrypted[sizeof plain + 16] = { 0 };
  encrypt_data_symmetric(ck, nonce, (const uint8_t *)plain, sizeof plain, (uint8_t *)encrypted);

  char plain2[sizeof plain] = { 0 };
  decrypt_data_symmetric(ck, nonce, (const uint8_t *)encrypted, sizeof encrypted, (uint8_t *)plain2);

  printf("%s\n", plain2);

  return strcmp(plain, plain2) == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
