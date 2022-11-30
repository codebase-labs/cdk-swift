#ifndef ic_h
#define ic_h

#include <stdint.h>

#if __wasm32__

__attribute__((__import_module__("ic0"),__import_name__("debug_print")))
extern void debug_print(const void *src, int32_t size);

__attribute__((__import_module__("ic0"),__import_name__("time")))
extern int64_t time(void);

#endif
#endif /* ic_h */
