---
date: 2019-05-17
---

## record类型

record
  * constructor
  * predicate
  * field-accessor

nongenerative

parent

protocol

sealed
  * 不能做parent
  * 不能make-record-type-descriptor

opaque
  * `record?`为假
  * 不能`record-rtd`
  * 若parent为opaque, 则child也为opaque

"
The define-record-type form is designed in such a way that it is normally possible for a compiler to determine the shapes of the record types it defines, including the offsets for all fields. This guarantee does not hold, however, when the parent-rtd clause is used, since the parent rtd might not be determinable until run time. Thus, the parent clause is preferred over the parent-rtd clause whenever the parent clause suffices. 
"
  eqv?

  rtd

  rcd




Syntactic (define-record) record definitions are expand-time generative by default, which means that a new record is created when the code is expanded. Expansion happens once for each form prior to compilation or interpretation, as when it is entered interactively, loaded from source, or compiled by compile-file. As a result, multiple evaluations of a single define-record form, e.g., in the body of a procedure called multiple times, always produce the same record type. 

Procedural (make-record-type) record definitions are run-time generative by default. That is, each call to make-record-type usually produces a new record type. As with the syntactic interface, the only exception occurs when the name of the record is specified as a gensym, in which case the record type is fully nongenerative. 



The mark (#n=) and reference (#n#) syntaxes may be used within the record syntax, with the result of creating shared or cyclic structure as desired. All cycles must be resolvable, however, without mutation of an immutable record field. That is, any cycle must contain at least one pointer through a mutable field, whether it is a mutable record field or a mutable field of a built-in object type such as a pair or vector. 

The default syntax may be used as input to the reader as well, as long as the corresponding record type has already been defined in the Scheme session in which the read occurs. The parameter record-reader may be used to specify a different name to be recognized by the reader in place of the generated name. Specifying a different name in this manner also changes the name used when the record is printed. This reader extension is disabled in an input stream after #!r6rs has been seen by the reader, unless #!chezscheme has been seen more recently. 

field type