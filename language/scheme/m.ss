(lambda (e r w ae)
      (let ((e (source-wrap e w ae)))
        (syntax-case e ()
          ((_ x)
           (let-values ([(e maps) (gen-syntax e (syntax x) r '() ellipsis? #f)])
             (regen e)))
(_ (syntax-error e)))))