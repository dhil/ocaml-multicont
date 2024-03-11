#define CAML_INTERNALS

#include <caml/mlvalues.h> // provides basic CAML macros and type definitions
#include <caml/fail.h>     // provides [caml_raise_out_of_memory]
#include <caml/alloc.h>    // provides [caml_alloc_1]
#include <caml/fiber.h>    // provides Stack_* macros, [struct stack_info]
#include <caml/memory.h>   // provides CAMLparam* and CAMLreturn* macros
#include <caml/misc.h>     // provides [CAMLnoalloc] macro
#include <caml/version.h>  // provides OCaml versioning macros

#ifdef NATIVE_CODE
#include <caml/stack.h>
#include <caml/frame_descriptors.h>
#endif

CAMLextern value caml_copy_int64 (int64_t); // defined in [ocaml/runtime/ints.c]

CAMLprim value multicont_test_lib_fiber_id(value fiber) {
  CAMLparam1(fiber);
  CAMLlocal1(id);
  struct stack_info *stack = Ptr_val(Field(fiber, 0));
  id = caml_copy_int64(stack->id);
  CAMLreturn(id);
}
