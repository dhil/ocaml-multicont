#ifndef MULTICONT_FIBER_PRIMITIVES_H
#define MULTICONT_FIBER_PRIMITIVES_H

#include <caml/mlvalues.h>
#include <caml/fiber.h>

struct stack_info* multicont_alloc_stack_noexc(mlsize_t wosize, value hval, value hexn, value heff);
void multicont_rewrite_exception_stack(struct stack_info *old_stack, value** exn_ptr, struct stack_info *new_stack);

#endif
