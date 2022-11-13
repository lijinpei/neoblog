# ChezScheme中Macro Expander的实现

## 源文件
主要是s/syntax.ss,涉及部分cmacro.ss,types.ss和nanopass定义的language.

## 主要数据结构

annotation: [s-exp+源代码信息](https://cisco.github.io/ChezScheme/csug9.5/syntax.html#./syntax:h11)
wrap/env/binding的介绍在syntax.ss:873, binding的表示在cmacros.ss:1738
property-list和compile-time-value是chez-scheme的[扩展特性](https://cisco.github.io/ChezScheme/csug9.5/syntax.html#./syntax:h4);

rho的实现是hash-table，还没看懂用途.
未知实现:
$sgetprop
$sputprop
$sremprop
$sc-put-cte

syntax-object的定义在types.ss:43
wrap/subst/ribcage/chunk的介绍在syntax.ss:1141

syntax-type
chi-top*
chi-top
chi-begin-body

local-label
global-label

fixed-ribcage
extensible-ribcage
  chunk:
    symbol-hashtable
    import-interfacce
    barrier
top-ribcage

resolved-id

$tc-field
$tc


lookup-global-lable/pl
store-global-subst
make-binding-wrap
make-resolved-id

visit-library
invoke-library

chi-top-library/top-program/top-module/frobs/expr/macro/body/lambda-clause/local-syntax/set!

parse-library/program/module/import/export/implicit/exports/define/define-syntax/define-property/meta/eval-when/alias/begin

update-mode-set
initial-mode-set

sllipsis?
strip

sc-expand
