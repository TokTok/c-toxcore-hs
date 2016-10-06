#include <HsFFI.h>

static __attribute__((constructor)) void my_enter(void)
{
  static char *argv[] = { "libtoxcore-hs.so", 0 };
  static char **argp = argv;
  static int argc = 1;
  hs_init(&argc, &argp);
}

static __attribute__((destructor)) void my_exit(void)
{
  hs_exit();
}
