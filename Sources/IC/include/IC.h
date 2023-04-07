#ifndef ic_h
#define ic_h

#include <stdint.h>

#if __wasm32__

__attribute__((__import_module__("ic0"),__import_name__("debug_print")))
extern void ic0_debug_print(const void *src, int32_t size);

__attribute__((__import_module__("ic0"),__import_name__("time")))
extern uint64_t ic0_time(void);

#endif
#endif /* ic_h */
