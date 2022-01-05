#define CAML_INTERNALS

#include <caml/mlvalues.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/fiber.h>
#include <caml/gc_ctrl.h>
#include <caml/memory.h>
#include <caml/callback.h>

#ifdef NATIVE_CODE
#include <caml/stack.h>
#include <frame_descriptors.h>
#endif

#include "fiber_primitives.h"

value multicont_is_null_continuation(value k) {
  CAMLparam1(k);
  CAMLnoalloc;
  value stack = Field(k, 0),
        null_stack = Val_ptr(NULL);

  CAMLreturn(Val_bool(stack == null_stack));
}

value multicont_promote(value k) {
  CAMLparam1(k);
  CAMLlocal1(r);

  value null_stk = Val_ptr(NULL);

  r = caml_alloc_1(Cont_tag, null_stk);
  caml_continuation_replace(r, Ptr_val(caml_continuation_use(k)));

  CAMLreturn(r);
}

value multicont_demote(value r) {
  CAMLparam1(r);
  CAMLlocal1(k);

  value null_stk = Val_ptr(NULL);

  k = caml_alloc_1(Cont_tag, null_stk);
  caml_continuation_replace(k, Ptr_val(caml_continuation_use(r)));

  CAMLreturn(k);
}

value multicont_clone_continuation(value k) {
  CAMLparam1(k);      // input continuation object
  CAMLlocal1(kclone); // resulting continuation object clone

  intnat stack_used;
  value null_stk = Val_ptr(NULL);

  struct stack_info *source,    // original stack segment pointed to by [k]
                    *current,   // iterator; points to the current stack segment
                    *clone,     // clone of [current]
                    *result;    // clone of [source]
  struct stack_info **link = &result;

  // Allocate an OCaml object with the continuation tag
  kclone = caml_alloc_1(Cont_tag, null_stk);

  // Retrieve the stack pointed to by the continuation [k]
  source = current = Ptr_val(caml_continuation_use(k));

  // Copy each stack segment in the chain
  while (current != NULL) {
    CAMLnoalloc;
    stack_used = Stack_high(current) - (value*)current->sp;

    // Allocate a fresh stack segment the size of [current]
    clone = multicont_alloc_stack_noexc(Stack_high(current) - Stack_base(current),
                                        Stack_handle_value(current),
                                        Stack_handle_exception(current),
                                        Stack_handle_effect(current));

    // Check whether allocation failed
    if (!clone) caml_raise_out_of_memory();

    // Copy the contents of [current] onto [clone]
    memcpy(Stack_high(clone) - stack_used,
           Stack_high(current) - stack_used,
           stack_used * sizeof(value));

#ifdef NATIVE_CODE
    // Rewrite exception pointer on the new stack segment
    clone->exception_ptr = current->exception_ptr;
    rewrite_exception_stack(current, (value**)&clone->exception_ptr, clone);
#endif

    // Set stack pointer on [clone]
    clone->sp = Stack_high(clone) - stack_used;

    // Prepare to handle the next stack segment
    *link = clone;
    link = &Stack_parent(clone);
    current = Stack_parent(current);
  }

  // Reattach the [source] stack to [k] (necessary as
  // [caml_continuation_use] deattaches it) and attach [result] to
  // [kclone]
  caml_continuation_replace(k, source);
  caml_continuation_replace(kclone, result);

  CAMLreturn(kclone);
}

value multicont_drop_continuation(value k) {
  struct stack_info *current,
                    *next = Ptr_val(caml_continuation_use(k));
  while (next != NULL) {
    current = next;
    next = Stack_parent(current);
    caml_free_stack(current);
  }
  return Val_unit;
}
