date: 2019-04-18
title: Scheme Macros
tags:
 - scheme
 - macros
---
这里记录的是我关于R6RS macro的一些总结。

## Top-Level

R6RS中top-level有两种:

- library
- top-level-program

其实还会遇到第三种

- interactive top level/REPL

Body有三种:

- body(指lambda，let等的body)
- library-body
- top-level-body

其中body和library-body基本相同，所以实际上有三个不同的东西:

- body(包括library body)
- top-level-body
- REPL

这三个东西的不同之处在于:

1. sub-form的顺序
    - body要求所有的definitoin在所有的expression之前。
    - top-level-body和REPL无此要求。
2. eval的方式
    - body和top-level-body可以在看到整个body之后再求值。
    - REPL对每个sub-form逐个求值，在看到后面的sub-form之前。

之所以做出这些要求的原因是和macro-expansion有关的，我们后面会看到为什么。

注意,R6RS中没有规定REPL的语义，REPL/interactive-environment的语义是实现规定的.原因在于，top-level-program和library要求body的包含的sub-form中,definition在前，expression在后,我们平时在使用REPL的时候经常是违背这一点的，所以R6RS中没有规定REPL的语义.(更准确地描述规则是按照import,definition,expressions的顺序,并且begin,let-syntax等form会splice到body中).注意其他需要body的地方，比如lambda和let,也是规定definition在前，expression在后。

## 在chez-scheme中使用不同的top-level

显然，在命令行输入scheme，进入的是REPL/interactive-environment。

compile-file=load

eval = compile + load
load = visit + revisit

import与load
## definition相当于letrec\*
为什么规定definition在前，expression在后，其实根本的原因在macro-expansion这里.

假如没有macro-expansion这件事,规定或者不规定defintion在前,expression在后,define相当于letrec\*其实是无所谓的.无论你如何规定这些规则，我总可以在扫描两边代码的代价以内，找到每个东西的定义(或者决定这个东西没有定义，是一个syntax-error)，这就像早年C规定变量定义要写在函数开头，后来C++放宽了这一规定；以及C/C++规定global-level先定义/声明后使用，但是Rust规定module level是letrec\*一样，怎么规定都无所谓.

但是scheme里有macro，这时候为了让macro-expander简单一点(也为了让代码不那么混乱)，就要加点更严格的要求了.

假设我们还希望definition的语义还是letrec*，这里的definition包括变量定义和syntax定义。这个要求是比较自然的一个事情，如果definition不是rec的话，那么需要引入很多括号来制造sub-scope，如果不是\*的话，你连`(let () (define x 1) (define y (+ x 1)))`都不能。

在这个前提下，scheme限制先definition后expression并不是因为,scheme（诞生于1975）是一门和K&R C（诞生于1972）差不多古老的语言，而是为了保证macro-expander可以single-pass，比如考虑下面这个代码:
```scheme
(cons car cdr)
(define-syntax cons (syntax-rules () ((_ x y) (define x y))))
```

当macro-expander看到第一行`(cons x car)`的时候,它知道cons是连接两个东西的那个预定义的函数,所以这一行按照cons的这个binding处理了,但是第三行把cons定义为了一个syntax，所以如果definition的语义是letrec*的话，第一行的这个语句就要重新处理.

你可能会说，这个很容易解决，我们先扫一编代码，记录一下那些东西定义为macro，然后再利用第一遍获得的信息，扫第二遍代码,这样看上去，我们可以在两遍以内处理完代码，也可以接受.

但是实际上，这样扫一遍再重新扫一遍，并不能保证线性时间内处理完代码。原因很简单，macro-use可以展开为macro-definition，这样你再第二遍展开macro-use的时候可能会展出来新的macro-definition，从而发现第一遍扫描中决定的哪些是/不是macro，以及哪些是/不是definition的信息是过时的.

所以，scheme要规定先definition，后expression，expression中混入definition是不合法的scheme代码。也正是这个原因，R6RS没有规定REPL的语义.

## undeferred部分的binding不能被更改
此外，还有一个问题，我们可以看R6RS中的这个例子(不是合法的scheme代码):
```scheme
(let-syntax ([def0 (syntax-rules () [(_ x) (define x 0)])])
  (let ([z 3])
    (def0 z)
    (define def0 list)
    (list z)))
```
这个例子的问题很明显,当macro-expander碰到def0的时候，它显然会按照第一个定义来展开代码，但是后面又重新定义了def0的语义，这样就不一致了。其他可能出现这个问题的地方还包括例如,macro transformer的body中的use.所以R6RS规定，
```
A definition in the sequence of forms must not define any identifier whose binding is used to determine the meaning of the undeferred portions of the definition or any definition that precedes it in the sequence of forms. 
```
详细的规则请参考[R6RS](http://www.r6rs.org/final/html/r6rs/r6rs-Z-H-13.html#node_chap_10).

##一些想法

允许variable definition interleave，不允许macro-definition interleave?