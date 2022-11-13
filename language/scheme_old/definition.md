# 关于"定义"

form是一个syntactic层的概念.definition和expression都是form.
definition不是expression,definition没有value.
definition可以分为variable definition和syntax definition.
form还可以按special-form(当form的第一个subform是syntactic keyword,或者form是identifier-macro),procrdure-call(反之)的标准划分.
form还可以分为derived-form和core-form;expander将derived-form展开为core-form;哪些form是core-from由实现决定.
Scheme中有三种"body", top-level-body, library-body和body(专指类似lambda-body那种).除了出现在不同的地方，三者的区别在于,library-body和body必须definition在expression前,top-level-body中definition和expression可以交错;library-body和body的区别较小，只在于body中必须至少有1个expression,library-body中可以有0个expression.

关于macro expand的过程:
先说body和library-body,这里因为definition和expression不会交错所以比较简单.首先，自左向右，递归展开, begin/let-syntax/letrec-syntax会被slicing到containing-body里，这些都比较基础，而且不会破坏definition和expression不交错的性质.然后这个过程中会遇到两种definition: varible-definition和syntax-definition.
对于syntax-definition,需要
1. 为定义的macro在当前body中建立相应的binding
2. evaluate右手边的transformer
对于2,意味着需要resolve相应表达式中的每一个identifier,但是这个identifier可能会在后面的definitions中建立定义(可能是variable或者macro定义)这时候就会出现两个矛盾的事情:
1. 感觉上,因为variable的定义是rec的,macro的定义似乎也应该是rec的.
2. 我们希望expand算法是single-pass的.
例如,如果1和2都成立的话,根据1,我们可以定义

Scheme Code = 
  Library
  | Top-Level-Program

Library = 
  Name [Imports] [Exports] [Library-Body]

Top-Level-Program = 
  Top-Level-Program-Body

eval-when:
compile-time state set
run-time state set
LCVRE
