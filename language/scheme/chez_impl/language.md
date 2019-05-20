---
title: Chez的中间表示
date: 2019-05-20
---

Chez中重要的的中间表示大概有下面这些:

* Lexpand: macro expander的输出
* Lsrc: Lsrc是source optimizer`cp0: Lsrc -> Lsrc`的操作对象.

Lexpand与Lsrc的区别
  1. Lsrc是Lexpand的一个terminal,反之Lsrc不了解Lexpand
  2. build/install library
  3. load/visit/revisit

* compile经历的IR:
  1. Lexpand
    * expand-Lexpand
  2. Lsrc
    * 这时候可能经过若干次cp0,然后`cpnanopass: Lsrc->L1`变换到L1
  3. L1到L16
    * 这是Chez的优化和代码生成的pass(Chez是AOT编译到机器码的)
    * 这些Language的`extends`关系如下(其中`a <- b`表示`b extends a`):
      1. `L1 <- L2 <- L3 <- L4 <- L4.5 <- L4.75 <- L4.875 <- L5 <- L6 <- L7 <- L9 <- L9.5 <- L9.75 <- L10 <- L10.5 <- L11 <- L11.5 <- L12`
      2. `L13 <- L13.5 <- L14`
      3. `L15a <- L15b <- L15c <- L15d <- L15e <- L16`
    * 最后`np-generate-code : L16 -> *`完成机器码的生成

* interpret经历的IR:
  * `ip1 : Lsrc -> Linterp`
  * `interpret-Lexpand : Lexpand (ir situation for-import? ofn eoo) -> *`
