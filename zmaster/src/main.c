#include <string.h>


char *copy(char *dst, const char *src, size_t len) {
  return strncpy(dst, src, len);
}
