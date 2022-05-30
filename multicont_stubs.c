#define CAML_INTERNALS

#include <caml/mlvalues.h> // provides basic CAML macros and type definitions
#include <caml/fail.h>     // provides [caml_raise_out_of_memory]
#include <caml/alloc.h>    // provides [caml_alloc_1]
#include <caml/fiber.h>    // provides Stack_* macros, [struct stack_info]
#include <caml/memory.h>   // provides CAMLparam* and CAMLreturn* macros
#include <caml/misc.h>     // provides [CAMLnoalloc] macro

#ifdef NATIVE_CODE
#include <caml/stack.h>
#include <caml/frame_descriptors.h>
#endif

#include "fiber_primitives.h" // provides copies of the hidden
                              // [alloc_stack_noexc] and
                              // [rewrite_exception_stack] functions
                              // from [fiber.c]

value multicont_promote(value k) {
  CAMLparam1(k);
  CAMLlocal1(r);

  value null_stk = Val_ptr(NULL);

  r = caml_alloc_1(Cont_tag, null_stk);

  // Move the stack from [k] to [r]
  {
    // Prevent the GC from running between [caml_continuation_use] and
    // [caml_continuation_replace]
    CAMLnoalloc;
    caml_continuation_replace(r, Ptr_val(caml_continuation_use(k)));
  }

  CAMLreturn(r);
}

value multicont_clone_continuation(value k) {
  CAMLparam1(k);      // input continuation object
  CAMLlocal1(kclone); // resulting continuation object clone

  intnat space_used;
  value null_stk = Val_ptr(NULL);

  struct stack_info *source,    // original stack segment pointed to by [k]
                    *current,   // iterator; points to the current stack segment
                    *clone,     // clone of [current]
                    *result;    // clone of [source]
  struct stack_info **link = &result;

  // Allocate an OCaml object with the continuation tag
  kclone = caml_alloc_1(Cont_tag, null_stk);
  {
    // Prevent the GC from running between the use of
    // [caml_continuation_use] and [caml_continuation_replace]
    CAMLnoalloc;

    // Retrieve the stack pointed to by the continuation [k]
    source = current = Ptr_val(caml_continuation_use(k));

    // Copy each stack segment in the chain
    while (current != NULL) {
      space_used = Stack_high(current) - (value*)current->sp;

      // Allocate a fresh stack segment the size of [current]
      clone = multicont_alloc_stack_noexc(Stack_high(current) - Stack_base(current),
                                          Stack_handle_value(current),
                                          Stack_handle_exception(current),
                                          Stack_handle_effect(current),
                                          current->id);
      // Check whether allocation failed
      if (!clone) caml_raise_out_of_memory();

      // Copy the contents of [current] onto [clone]
      memcpy(Stack_high(clone) - space_used,
             Stack_high(current) - space_used,
             space_used * sizeof(value));

#ifdef NATIVE_CODE
      // Rewrite exception pointer on the new stack segment
      clone->exception_ptr = current->exception_ptr;
      multicont_rewrite_exception_stack(current, (value**)&clone->exception_ptr, clone);
#endif

      // Set stack pointer on [clone]
      clone->sp = Stack_high(clone) - space_used;

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
  }

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
