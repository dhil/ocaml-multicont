#!/bin/sh
set -ue
echo -n "("
echo -n "-cclib -L$(opam var lib)/multicont"
echo ")"
