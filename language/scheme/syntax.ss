(global-extend 'core 'syntax
  (let ()
    (define gen-syntax
      (lambda (src e r maps ellipsis? vec?)
        (if (id? e)
            (cond
              [(lookup-pattern-variable (id->label e empty-wrap) r) =>
               (lambda (var.lev)
                 (let-values ([(var maps) (gen-ref src (car var.lev) (cdr var.lev) maps)])
                   (values `(ref ,var) maps)))]
              [(ellipsis? e) (syntax-error src "misplaced ellipsis in syntax form")]
              [else (values `(quote ,e) maps)])
            (syntax-case e ()
              ((dots e)
               (ellipsis? (syntax dots))
               (if vec?
                   (syntax-error src "misplaced ellipsis in syntax template")
                   (gen-syntax src (syntax e) r maps (lambda (x) #f) #f)))
              ((x dots . y)
               ; this could be about a dozen lines of code, except that we
               ; choose to handle (syntax (x ... ...)) forms
               (ellipsis? (syntax dots))
               (let f ((y (syntax y))
                       (k (lambda (maps)
                            (let-values ([(x maps)
                                          (gen-syntax src (syntax x) r
                                            (cons '() maps) ellipsis? #f)])
                              (if (null? (car maps))
                                  (syntax-error src
                                    "extra ellipsis in syntax form")
                                  (values (gen-map x (car maps))
                                          (cdr maps)))))))
                 (syntax-case y ()
                   ((dots . y)
                    (ellipsis? (syntax dots))
                    (f (syntax y)
                       (lambda (maps)
                         (let-values ([(x maps) (k (cons '() maps))])
                           (if (null? (car maps))
                               (syntax-error src
                                 "extra ellipsis in syntax form")
                               (values (gen-mappend x (car maps))
                                       (cdr maps)))))))
                   (_ (let-values ([(y maps) (gen-syntax src y r maps ellipsis? vec?)])
                        (let-values ([(x maps) (k maps)])
                          (values (gen-append x y) maps)))))))
              ((x . y)
               (let-values ([(xnew maps) (gen-syntax src (syntax x) r maps ellipsis? #f)])
                 (let-values ([(ynew maps) (gen-syntax src (syntax y) r maps ellipsis? vec?)])
                   (values (gen-cons e (syntax x) (syntax y) xnew ynew)
                           maps))))
              (#(x1 x2 ...)
               (let ((ls (syntax (x1 x2 ...))))
                 (let-values ([(lsnew maps) (gen-syntax src ls r maps ellipsis? #t)])
                   (values (gen-vector e ls lsnew) maps))))
              (#&x
               (let-values ([(xnew maps) (gen-syntax src (syntax x) r maps ellipsis? #f)])
                 (values (gen-box e (syntax x) xnew) maps)))
              (_ (values `(quote ,e) maps))))))

    (define gen-ref
      (lambda (src var level maps)
        (if (fx= level 0)
            (values var maps)
            (if (null? maps)
                (syntax-error src "missing ellipsis in syntax form")
                (let-values ([(outer-var outer-maps) (gen-ref src var (fx- level 1) (cdr maps))])
                  (let ((b (assq outer-var (car maps))))
                    (if b
                        (values (cdr b) maps)
                        (let ((inner-var (gen-var 'tmp)))
                          (values inner-var
                                  (cons (cons (cons outer-var inner-var)
                                              (car maps))
                                        outer-maps))))))))))

    (define gen-append
      (lambda (x y)
        (if (equal? y '(quote ()))
            x
            `(append ,x ,y))))

    (define gen-mappend
      (lambda (e map-env)
        `(apply (primitive append) ,(gen-map e map-env))))

    (define gen-map
      (lambda (e map-env)
        (let ((formals (map cdr map-env))
              (actuals (map (lambda (x) `(ref ,(car x))) map-env)))
          (cond
            ((eq? (car e) 'ref)
             ; identity map equivalence:
             ; (map (lambda (x) x) y) == y
             (car actuals))
            ((andmap
                (lambda (x) (and (eq? (car x) 'ref) (memq (cadr x) formals)))
                (cdr e))
             ; eta map equivalence:
             ; (map (lambda (x ...) (f x ...)) y ...) == (map f y ...)
             `(map (primitive ,(car e))
                   ,@(map (let ((r (map cons formals actuals)))
                            (lambda (x) (cdr (assq (cadr x) r))))
                          (cdr e))))
            (else `(map (lambda ,formals ,e) ,@actuals))))))

   ; 12/12/00: semantic change: we now return original syntax object (e)
   ; if no pattern variables were found within, to avoid dropping
   ; source annotations prematurely.  the "syntax returns lists" for
   ; lists in its input guarantee counts only for substructure that
   ; contains pattern variables
   ; test with (define-syntax a (lambda (x) (list? (syntax (a b)))))
   ;           a => #f
    (define gen-cons
      (lambda (e x y xnew ynew)
        (case (car ynew)
          ((quote)
           (if (eq? (car xnew) 'quote)
               (let ([xnew (cadr xnew)] [ynew (cadr ynew)])
                 (if (and (eq? xnew x) (eq? ynew y))
                     `',e
                     `'(,xnew . ,ynew)))
               (if (eq? (cadr ynew) '()) `(list ,xnew) `(cons ,xnew ,ynew))))
          ((list) `(list ,xnew ,@(cdr ynew)))
          (else `(cons ,xnew ,ynew)))))

   ; test with (define-syntax a
   ;             (lambda (x)
   ;               (let ((x (syntax #(a b))))
   ;                 (and (vector? x)
   ;                      (not (eq? (vector-ref x 0) 'syntax-object))))))
   ;           a => #f
    (define gen-vector
      (lambda (e ls lsnew)
        (cond
          ((eq? (car lsnew) 'quote)
           (if (eq? (cadr lsnew) ls)
               `',e
               `(quote #(,@(cadr lsnew)))))
          ((eq? (car lsnew) 'list) `(vector ,@(cdr lsnew)))
          (else `(list->vector ,lsnew)))))

   ; test with (define-syntax a (lambda (x) (box? (syntax #&(a b)))))
   ;           a  => #f
    (define gen-box
      (lambda (e x xnew)
        (cond
          ((eq? (car xnew) 'quote)
           (if (eq? (cadr xnew) x)
               `',e
               `(quote #&,(cadr xnew))))
          (else `(box ,xnew)))))

    (define regen
      (lambda (x)
        (case (car x)
          ((ref) (build-lexical-reference no-source (cadr x)))
          ((primitive) (build-primref 3 (cadr x)))
          ((quote) (build-data no-source (cadr x)))
          ((lambda) (build-lambda no-source (cadr x) (regen (caddr x))))
          ((map) (let ((ls (map regen (cdr x))))
                   (if (fx= (length ls) 2)
                       (build-call no-source
                         (build-primref 3 'map)
                         ls)
                       (build-call no-source
                         (build-primref 3 '$map)
                         (cons (build-data #f 'syntax) ls)))))
          (else (build-call no-source
                  (build-primref 3 (car x))
                  (map regen (cdr x)))))))

    (lambda (e r w ae)
      (let ((e (source-wrap e w ae)))
        (syntax-case e ()
          ((_ x)
           (let-values ([(e maps) (gen-syntax e (syntax x) r '() ellipsis? #f)])
             (regen e)))
(_ (syntax-error e)))))))