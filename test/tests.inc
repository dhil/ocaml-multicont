; async tests
(rule
 (with-stdout-to async.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/async.exe))))

(rule
 (alias runtest)
 (action (diff async.expected async.output)))

(rule
 (with-stdout-to async.bc.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/async.bc.exe))))

(rule
 (alias runtest)
 (action (diff async.expected async.bc.output)))

; choice tests
(rule
 (with-stdout-to choice.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/choice.exe))))

(rule
 (alias runtest)
 (action (diff choice.expected choice.output)))

(rule
 (with-stdout-to choice.bc.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/choice.bc.exe))))

(rule
 (alias runtest)
 (action (diff choice.expected choice.bc.output)))

; generic_count tests
(rule
 (with-stdout-to generic_count.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/generic_count.exe))))

(rule
 (alias runtest)
 (action (diff generic_count.expected generic_count.output)))

(rule
 (with-stdout-to generic_count.bc.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/generic_count.bc.exe))))

(rule
 (alias runtest)
 (action (diff generic_count.expected generic_count.bc.output)))

; nqueens tests
(rule
 (with-stdout-to nqueens.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/nqueens.exe))))

(rule
 (alias runtest)
 (action (diff nqueens.expected nqueens.output)))

(rule
 (with-stdout-to nqueens.bc.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/nqueens.bc.exe))))

(rule
 (alias runtest)
 (action (diff nqueens.expected nqueens.bc.output)))

; return tests
(rule
 (with-stdout-to return.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/return.exe))))

(rule
 (alias runtest)
 (action (diff return.expected return.output)))

(rule
 (with-stdout-to return.bc.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/return.bc.exe))))

(rule
 (alias runtest)
 (action (diff return.expected return.bc.output)))

; supervised tests
(rule
 (with-stdout-to supervised.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/supervised.exe))))

(rule
 (alias runtest)
 (action (diff supervised.expected supervised.output)))

(rule
 (with-stdout-to supervised.bc.output
 (setenv "LD_LIBRARY_PATH" "."
   (run %{workspace_root}/examples/supervised.bc.exe))))

(rule
 (alias runtest)
 (action (diff supervised.expected supervised.bc.output)))

; unique_fibers tests
(rule
 (alias runtest)
 (action
   (setenv "TEST_UNIQUE_FIBERS" "false"
     (setenv "LD_LIBRARY_PATH" "."
       (run %{workspace_root}/test/lib/unique_fibers.bc.exe)))))

(rule
 (alias runtest)
 (action
   (setenv "TEST_UNIQUE_FIBERS" "false"
     (setenv "LD_LIBRARY_PATH" "."
       (run %{workspace_root}/test/lib/unique_fibers.exe)))))
