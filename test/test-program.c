#include "Network/Tox/CExport/CryptoCore_stub.h"

#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void *must_dlsym(void *lib, char const *name)
{
  void *sym = dlsym(lib, name);
  if (!sym) {
    fprintf(stderr, "error resolving %s: %s\n", name, dlerror());
    exit(EXIT_FAILURE);
  }
  return sym;
}

int main(void)
{
  char path[1024] = { 0 };
  if (!getcwd(path, sizeof path)) {
    perror("getcwd");
    return EXIT_FAILURE;
  }
  strncat(path, "/libtoxcore-hs.so", sizeof path - strlen(path) - 1);

  // Load library.
  void *lib = dlopen(path, RTLD_NOW | RTLD_LOCAL);
  if (!lib) {
    fprintf(stderr, "error while loading libtoxcore-hs.so: %s\n", dlerror());
    return EXIT_FAILURE;
  }

#define SYM(name) \
  typeof(name) *dl_##name = must_dlsym(lib, #name)

  // Resolve symbols.
  SYM(decrypt_data_symmetric);
  SYM(encrypt_data_symmetric);
  SYM(encrypt_precompute);
  SYM(random_64b);
  SYM(random_int);
  SYM(random_nonce);

  printf("%u\n", dl_random_int());
  printf("%lu\n", dl_random_64b());

  uint8_t pk[32] = { 0, 1, 2, 3, 4 };
  uint8_t sk[32] = { 0, 4, 3, 2, 1 };
  uint8_t ck[32] = { 0 };
  dl_encrypt_precompute(pk, sk, ck);

  uint8_t nonce[24] = { 0 };
  dl_random_nonce(nonce);

  char plain[] = "hello world";
  char encrypted[sizeof plain + 16] = { 0 };
  dl_encrypt_data_symmetric(ck, nonce, plain, sizeof plain, encrypted);

  char plain2[sizeof plain] = { 0 };
  dl_decrypt_data_symmetric(ck, nonce, encrypted, sizeof encrypted, plain2);

  printf("%s\n", plain2);

  // Unload library.
  if (dlclose(lib) != 0) {
    fprintf(stderr, "error while unloading libtoxcore-hs.so: %s\n", dlerror());
    return EXIT_FAILURE;
  }

  return strcmp(plain, plain2) == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
