# ChezScheme

## ChezScheme源码分析

### nanopass框架
[Andy Keep's scheme-to-c demo](scheme-to-c.html)

### Hygienic Macro Expander
[Schme中Macro Expander的实现](syntax.html)

### 栈/continuation/GC

### bootstrap

### s目录

nanopass定义的language:

base-lang.ss
expand-lang.ss
np-languages.ss

nanopass定义的pass:

cpnanopass.ss
cp0.ss
cprep.ss
cpvalid.ss
cpletrec.ss
cpcommonize.ss
cpcheck.ss

interpret.ss
compile.ss

ppc32.ss
arm32.ss

其他与机器相关的文件:

x86.ss
x86_64.ss

与prim相关:

mathprims.ss
primdata.ss
priminfo.ss
primref.ss
prims.ss
primvars.ss

macro expander:

syntax.ss

作用未知但应该很重要:

cmacros.ss
4.ss
5_1.ss
5_2.ss
5_3.ss
5_4.ss
5_5.ss
5_6.ss
5_7.ss
6.ss
7.ss
mkheader.ss似乎与生成boot/m/equates.h和boot/m/scheme.h相关

猜测其他文件主要是库相关的文件

### c目录

### configure/makefiles
