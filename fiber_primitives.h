#ifndef MULTICONT_FIBER_PRIMITIVES_H
#define MULTICONT_FIBER_PRIMITIVES_H

#include <caml/mlvalues.h>
#include <caml/fiber.h>

struct stack_info* multicont_alloc_stack_noexc(mlsize_t wosize, value hval, value hexn,
                                               value heff, int64_t id);
#ifdef NATIVE_CODE
void multicont_rewrite_exception_stack(struct stack_info *old_stack, value** exn_ptr,
                                       struct stack_info *new_stack);
#endif

#ifdef UNIQUE_FIBERS
// Since commit ocaml/ocaml#e12b508 fibers are equipped with a unique
// identifier. The fiber id generator is hidden/private in the OCaml
// runtime. Thus if we want to maintain uniqueness of cloned fibers,
// then we have to roll our own generator. Looking at the
// implementation of the stock OCaml generator it seems that it only
// uses the non-negative range of `int64_t`, therefore to ensure
// uniqueness amongst all fibers, we can use the negative range of
// `int64_t` to assign identifiers to cloned fibers.
extern _Atomic int64_t multicont_fiber_id;
#define MULTICONT_NEXT_FIBER_ID atomic_fetch_sub(&multicont_fiber_id, 1)
#endif

#endif
