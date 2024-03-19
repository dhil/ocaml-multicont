#define CAML_INTERNALS

#include <caml/fiber.h>    // provides Stack_* macros, [struct stack_info]
#include <caml/memory.h>   // provides CAMLparam* and CAMLreturn* macros

CAMLextern value caml_copy_int64 (int64_t); // defined in [ocaml/runtime/ints.c]

CAMLprim value multicont_test_lib_fiber_id(value fiber) {
  CAMLparam1(fiber);
  CAMLlocal1(id);
  struct stack_info *stack = Ptr_val(Field(fiber, 0));
  id = caml_copy_int64(stack->id);
  CAMLreturn(id);
}
