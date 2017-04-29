(define *label-num* 0)
(define (gen opcode . args)
  (list (cons opcode args)))
(define (seq . code)
  (apply append code))
(define (gen-label)
  (string->symbol (format "L_~a" (+ 1 *label-num*))))
(define (gen-var var env)
  (let ((p (in-env-p var env)))
    (if p
        (gen 'LVAR (car p) (second p))
        (gen 'GVAR var))))
(define (gen-set var env)
  (let ((p (in-env-p var env)))
    (if p
        (gen 'LSET (car p) (second p))
        (gen 'GSET var))))
(define (comp-lambda args body env)
  `('fn
    ,(seq (gen 'ARGS (length args))
          (comp-begin body (cons args env))
          (gen 'RETURN))))
(define (fn-p x)
  (eq? 'fn (car x)))
(define (compiler x)
  (set! *label-num* 0)
  (seq
   (gen "global _scheme_entry")
   (gen "section .text")
   (gen "_scheme_entry:")
   (gen 'mov 'rax 42)
;   (comp-lambda '() (list x) '() )
   (gen "ret")))
(define (comp-begin exps env)
  (cond ((null? exps) (gen 'CONST '() ))
        ((= 1 (length exps)) (comp (car exps) env))
        (else (seq (comp (car exps) env)
                   (gen 'POP)
                   (comp-begin (cdr exps) env)))))
(define (comp-if pred then else env)
  (let ((l1 (gen-label))
        (l2 (gen-label)))
    (seq (comp pred env) (gen 'FJUMP L1)
         (comp then env) (gen 'JUMP L2)
         (list l1) (comp else env)
         (list l2))))
(define (comp x env)
  "Compile the expression into a list of instructions"
  (cond
;   ((symbol? x)  (gen-var x env))
   ((integer? x) (gen 'PUSH x))
                                        ; TODO macros
   ((case (car x)
      (quote (gen 'PUSH (cadr x)))
      (asm   (gen (cadr x) (caddr x)))
      ;; (begin (comp-begin (cdr x) env))
      ;; (set!  (seq (comp (third x) env) (gen-set (second x) env)))
      ;; (if    (comp-if (second x) (third x) (fourth x) env))
      ;; (lambda (gen 'FN (comp-lambda (second x) (cdr (cdr x)) env)))
      ;; (else  (seq (mappend (lambda (y) (comp y env)) (cdr x))
      ;;             (comp (car x) env)
      ;;             (gen 'CALL (length (cdr x)))))
      ))
   ))
(define (show-fn fn )
  (if (pair? fn)
      (if (eq? 'fn (car fn))
          (begin
            (format #t "~%")
            (for-each (lambda (instr)
                        (if (symbol? instr)
                            (format #t "~a:" instr)
                            (begin
                              (for-each show-fn instr)
                              (format #t "~%")))) (cdr fn)))
          (begin
            (format #t "~a" (car fn))
            (format #t "~{ ~a, ~a ~}" (cdr fn))
;            (for-each show-fn fn)
            (format #t "~%")))
      (format #t "~a " fn)))
