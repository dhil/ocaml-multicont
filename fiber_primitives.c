/**************************************************************************/
/*                                                                        */
/*                                 OCaml                                  */
/*                                                                        */
/*      KC Sivaramakrishnan, Indian Institute of Technology, Madras       */
/*                   Tom Kelly, OCaml Labs Consultancy                    */
/*                Stephen Dolan, University of Cambridge                  */
/*                                                                        */
/*   Copyright 2021 Indian Institute of Technology, Madras                */
/*   Copyright 2021 OCaml Labs Consultancy                                */
/*   Copyright 2019 University of Cambridge                               */
/*                                                                        */
/*   All rights reserved.  This file is distributed under the terms of    */
/*   the GNU Lesser General Public License version 2.1, with the          */
/*   special exception on linking described in the file LICENSE.          */
/*                                                                        */
/**************************************************************************/

#define CAML_INTERNALS

#include <caml/mlvalues.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/fiber.h>
#include <caml/gc_ctrl.h>
#include <caml/memory.h>

#ifdef NATIVE_CODE
#include <caml/stack.h>
#include <caml/frame_descriptors.h>
#endif

#ifdef USE_MMAP_MAP_STACK
#include <sys/mman.h>
#endif

#define NUM_STACK_SIZE_CLASSES 5 // defined in runtime/fiber.c

Caml_inline struct stack_info* alloc_for_stack (mlsize_t wosize)
{
  size_t len = sizeof(struct stack_info) +
               sizeof(value) * wosize +
               8 /* for alignment to 16-bytes, needed for arm64 */ +
               sizeof(struct stack_handler);
#ifdef USE_MMAP_MAP_STACK
  struct stack_info* si;
  si = mmap(NULL, len, PROT_WRITE | PROT_READ,
             MAP_ANONYMOUS | MAP_PRIVATE | MAP_STACK, -1, 0);
  if (si == MAP_FAILED)
    return NULL;

  si->size = len;
  return si;
#else
  return caml_stat_alloc_noexc(len);
#endif /* USE_MMAP_MAP_STACK */
}

Caml_inline struct stack_info** stack_cache_bucket (mlsize_t wosize) {
  mlsize_t size_bucket_wsz = caml_fiber_wsz;
  struct stack_info** size_bucket = Caml_state->stack_cache;
  struct stack_info** end = size_bucket + NUM_STACK_SIZE_CLASSES;

  /* wosize is in stack cache bucket n iff wosize == caml_fiber_wsz * 2**n */
  while (size_bucket < end) {
    if (wosize == size_bucket_wsz)
      return size_bucket;
    ++size_bucket;
    size_bucket_wsz += size_bucket_wsz;
  }

  return NULL;
}

static struct stack_info*
alloc_size_class_stack_noexc(mlsize_t wosize, struct stack_info** size_bucket,
                             value hval, value hexn, value heff)
{
  struct stack_info* stack;
  struct stack_handler* hand;

  CAML_STATIC_ASSERT(sizeof(struct stack_info) % sizeof(value) == 0);
  CAML_STATIC_ASSERT(sizeof(struct stack_handler) % sizeof(value) == 0);

  if (size_bucket != NULL && *size_bucket != NULL) {
    stack = *size_bucket;
    *size_bucket = (struct stack_info*)stack->exception_ptr;
    CAMLassert(stack->size_bucket == stack_cache_bucket(wosize));
    hand = stack->handler;
  } else {
    /* couldn't get a cached stack, so have to create one */
    stack = alloc_for_stack(wosize);
    if (stack == NULL) {
      return NULL;
    }

    stack->size_bucket = size_bucket;

    /* Ensure 16-byte alignment because some architectures require it */
    hand = (struct stack_handler*)
     (((uintnat)stack + sizeof(struct stack_info) + sizeof(value) * wosize + 8)
      & ((uintnat)-1 << 4));
    stack->handler = hand;
  }

  hand->handle_value = hval;
  hand->handle_exn = hexn;
  hand->handle_effect = heff;
  hand->parent = NULL;
  stack->sp = (value*)hand;
  stack->exception_ptr = NULL;
#ifdef DEBUG
  stack->magic = 42;
#endif
  CAMLassert(Stack_high(stack) - Stack_base(stack) == wosize ||
             Stack_high(stack) - Stack_base(stack) == wosize + 1);
  return stack;

}

/* allocate a stack with at least "wosize" usable words of stack */
struct stack_info* multicont_alloc_stack_noexc(mlsize_t wosize, value hval,
                                               value hexn, value heff)
{
  struct stack_info** size_bucket = stack_cache_bucket(wosize);
  return alloc_size_class_stack_noexc(wosize, size_bucket, hval, hexn, heff);
}


#ifdef NATIVE_CODE
/* Update absolute exception pointers for new stack*/
void multicont_rewrite_exception_stack(struct stack_info *old_stack,
                                       value** exn_ptr, struct stack_info *new_stack) {
  /* fiber_debug_log("Old [%p, %p]", Stack_base(old_stack), Stack_high(old_stack)); */
  /* fiber_debug_log("New [%p, %p]", Stack_base(new_stack), Stack_high(new_stack)); */
  if(exn_ptr) {
    /* fiber_debug_log ("*exn_ptr=%p", *exn_ptr); */

    while (Stack_base(old_stack) < *exn_ptr &&
           *exn_ptr <= Stack_high(old_stack)) {
#ifdef DEBUG
      value* old_val = *exn_ptr;
#endif
      *exn_ptr = Stack_high(new_stack) - (Stack_high(old_stack) - *exn_ptr);

      /* fiber_debug_log ("Rewriting %p to %p", old_val, *exn_ptr); */

      CAMLassert(Stack_base(new_stack) < *exn_ptr);
      CAMLassert((value*)*exn_ptr <= Stack_high(new_stack));

      exn_ptr = (value**)*exn_ptr;
    }
    /* fiber_debug_log ("finished with *exn_ptr=%p", *exn_ptr); */
  } else {
    /* fiber_debug_log ("exn_ptr is null"); */
  }
}
#endif
