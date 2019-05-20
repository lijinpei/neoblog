date: 2019-04-19
title: Scheme: Nanopass Framework
tag:
 - scheme
 - compiler
---
## Nanopass是什么?
Nanopass是R. Kent Dybvig的学生Andy Keep用scheme开发的一个编译器框架。它不是一个toy或者纯academic的框架，在chez scheme中的中间优化，代码生成和宏展开的结果都用到了nanopass。在nanopass中有两个重要的概念:

- language
- pass

Language通过language的grammar定义,也就是我们熟悉的terminal/non-terminal, reduction rule这些东西。例如，chez scheme中的宏展开器current-expand，通常也就是sc-expand,这个东西的输入是read函数返回的那种东西：s-expression/datum，它的输出，应该是展开过的s-expression/datum，文档里写的是
```
current-expand ...  may be set another procedure, but since the format of expanded code expected by the compiler and interpreter is not publicly documented, only sc-expand produces correct output, so the other procedure must ultimately be defined in terms of sc-expand. 
```
实际上，它的输出是用nanopass定义的一种语言Lexpand（中的Outer non-terminal）.

Pass是对Language的变换。接上面那个例子，我们拿到macro expander给我们的展开结果Lexpand以后，可以interprete这个结果或者compile这个结果。对于编译，可以想象编译的过程要经过很多中间结果/中间表示，例如closure conversion，做这一步/这个pass之前的中间表示/language里有closure的中间表示，做完这一步，中间表示里没有closure，但是有function pointer和closure pointer(非常尴尬，我现在只能想起来这一个比较好的例子，把derived form展开为core form这一步是在macro expander中做的，所以和中间表示关系不大；cse/gvn/constant propagation这种变换其实不需要不同的中间表示)。经过很多pass和中间language(chez scheme中有大约20个中间表示，相应有大约这个数目的pass)之后，最后有一个pass根据language(chez scheme中是L16)输出machine code.对于解释执行，就只有一个pass输入是Lexpand，没有输出,直接解释执行.Pass的输入可以是一个language附加其他一些输入，或者可以没有language做输入，比如expand作为pass看待的话，或者read作为pass看待的话，他们的输入就不是language，pass的输出可以是language，附加一些额外的输出，或者也可以不是language，例如编译过程中的最后一个pass的输出是机器码，不包含language，解释过程的pass就没有输出。

Nanopass本身只有5000多行代码，你可以看它的[doc](https://github.com/akeep/nanopass-framework/tree/master/doc),另外一个[文档](https://www.cs.indiana.edu/~dyb/pubs/nano-jfp.pdf)，一个可以把[部分scheme编译到C的toy](https://github.com/akeep/scheme-to-c)，只有3500行，而且有一小半都是注释。

## Language

## Pass

## Helper