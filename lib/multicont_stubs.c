#define CAML_INTERNALS

#include <caml/mlvalues.h> // provides basic CAML macros and type definitions
#include <caml/fail.h>     // provides [caml_raise_out_of_memory]
#include <caml/alloc.h>    // provides [caml_alloc_1]
#include <caml/fiber.h>    // provides Stack_* macros, [struct stack_info]
#include <caml/memory.h>   // provides CAMLparam* and CAMLreturn* macros
#include <caml/misc.h>     // provides [CAMLnoalloc] macro
#include <caml/version.h>  // provides OCaml versioning macros

#include <string.h>

#ifdef NATIVE_CODE
#include <caml/stack.h>
#include <caml/frame_descriptors.h>
#endif

#include "fiber_primitives.h" // provides [MULTICONT_NEXT_FIBER_ID]
                              // generator.

// NOTE(dhil): The representation of continuations was changed in
// OCaml 5.2. In OCaml 5.2+ a continuation is a pair of stack segments
// (first_segment, last_segment) which together forms the complete
// stack chain from effect invocation site to handle site. Here,
// first_segment is the segment where the effect was initially
// performed and last_segment is segment that had the appropriate
// handler installed.
//
// Prior to OCaml 5.2 the continuation was simply a pointer to
// previous stack segment that performed or reperformed the effect.
#if OCAML_VERSION_MAJOR >= 5 && OCAML_VERSION_MINOR > 1
#define MULTICONT52 1
#else
#define MULTICONT52 0
#endif

CAMLprim value multicont_promote(value k) {
  CAMLparam1(k);
  CAMLlocal1(r);

  value null_stk = Val_ptr(NULL);

#if MULTICONT52
  r = caml_alloc_2(Cont_tag, null_stk, null_stk);
#else
  r = caml_alloc_1(Cont_tag, null_stk);
#endif

  // Move the stack from [k] to [r]
  {
    // Prevent the GC from running between [caml_continuation_use] and
    // [caml_continuation_replace]
    CAMLnoalloc;
    caml_continuation_replace(r, Ptr_val(caml_continuation_use(k)));
#if MULTICONT52
    caml_modify(&Field(r, 1), Field(k, 1));
#endif
  }

  CAMLreturn(r);
}

CAMLprim value multicont_clone_continuation(value k) {
  CAMLparam1(k);      // input continuation object
  CAMLlocal1(kclone); // resulting continuation object clone

  intnat space_used;
  value null_stk = Val_ptr(NULL);

  struct stack_info *source,    // original stack segment pointed to by [k]
                    *current,   // iterator; points to the current stack segment
                    *clone,     // clone of [current]
                    *result;    // clone of [source]
  struct stack_info **link = &result;
#if MULTICONT52
  struct stack_info *last_segment; // the last segment of the stack chain
#endif

  // Allocate an OCaml object with the continuation tag
#if MULTICONT52
  kclone = caml_alloc_2(Cont_tag, null_stk, null_stk);
#else
  kclone = caml_alloc_1(Cont_tag, null_stk);
#endif
  {
    // Prevent the GC from running between the use of
    // [caml_continuation_use] and [caml_continuation_replace]
    CAMLnoalloc;

    // Retrieve the stack pointed to by the continuation [k]
    source = current = Ptr_val(caml_continuation_use(k));

    // NOTE: We know now that [current] is non-null, as otherwise
    // [caml_continuation_use] would have raised an exception.
    // Copy each stack segment in the chain
    do {
      space_used = Stack_high(current) - (value*)current->sp;

      int64_t fiber_id;
#ifdef UNIQUE_FIBERS
      fiber_id = MULTICONT_NEXT_FIBER_ID;
#else
      fiber_id = current->id;
#endif

      // Allocate a fresh stack segment the size of [current]
      clone = caml_alloc_stack_noexc(Stack_high(current) - Stack_base(current),
                                          Stack_handle_value(current),
                                          Stack_handle_exception(current),
                                          Stack_handle_effect(current),
                                          fiber_id);
      // Check whether allocation failed
      if (!clone) caml_raise_out_of_memory();

      // Copy the contents of [current] onto [clone]
      memcpy(Stack_high(clone) - space_used,
             Stack_high(current) - space_used,
             space_used * sizeof(value));

#ifdef NATIVE_CODE
      // Rewrite exception pointer on the new stack segment
      clone->exception_ptr = current->exception_ptr;
      caml_rewrite_exception_stack(current, (value**)&clone->exception_ptr, clone);
#endif

      // Set stack pointer on [clone]
      clone->sp = Stack_high(clone) - space_used;

      // Prepare to handle the next stack segment
#if MULTICONT52
      last_segment = clone;
#endif
      *link = clone;
      link = &Stack_parent(clone);
      current = Stack_parent(current);
    } while (current != NULL);

#if MULTICONT52
    caml_modify(&Field(kclone, 1), Val_ptr(last_segment));
#endif

    // Reattach the [source] stack to [k] (necessary as
    // [caml_continuation_use] deattaches it) and attach [result] to
    // [kclone]
    caml_continuation_replace(k, source);
    caml_continuation_replace(kclone, result);
  }

  CAMLreturn(kclone);
}

CAMLprim value multicont_drop_continuation(value k) {
  CAMLparam1(k);
  struct stack_info *current,
                    *next = Ptr_val(caml_continuation_use(k));
  while (next != NULL) {
    current = next;
    next = Stack_parent(current);
    caml_free_stack(current);
  }
  CAMLreturn(Val_unit);
}
