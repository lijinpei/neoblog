# 冥想盆: My Collection of Posts about C/C++

"我若千岁也没有这么多回忆。"

## 语言律师/Language Lawyer

[我的C++标准的读书笔记](standard.html)

### 对象

#### 初始化

#### 类型转换
##### 隐式转换
##### 显式转换
##### reinterpret_cast
##### dynamic_cast

### 函数/function
左值/右值
#### 函数重载

### 引用/Reference

#### 值类别/Value Category
#### decay

### 命名空间/namespace

### 模板/Templates

#### 名字查询
qualified-name/unqualified-name
dependent-name/nondependent-name

#### 模板实参推导/Template Argument Deduction

#### 实例化/Instantiation

#### 特化/Specialization

### 虚函数

### lambda表达式与闭包类型/Lambda Expression and Closure Type

## 库专家/Libraries Expert
[C++库学习笔记](libraries.html)
## 奇技淫巧/Disgusting Tricks

__is_constant(thanks to some of my group-mates for mention this to me)

* [lkml article](https://lkml.org/lkml/2018/3/20/845)
* [lwn article](https://lwn.net/Articles/750306/)

member dectecter

* https://en.wikibooks.org/wiki/More_C%2B%2B_Idioms/Member_Detector
* TODO: example in llvm DenseMap
* TODO: some fine difference about two flavor of member detecter

## 惯例

Rule of Five

* [cppreference article](https://en.cppreference.com/w/cpp/language/rule_of_three)
* [Everything You Ever Wanted to Know About Move Semantics](https://www.slideshare.net/ripplelabs/howard-hinnant-accu2014)

## 二进制/Binary
[Ulrich Drepper's blog](https://www.akkadia.org/drepper/) on NPTL/shared library/other things.

[SysV abi](sysv_abi.html)

### 对象布局/Object Layout

### 二进制接口/ABI
* [ELF ABI](https://refspecs.linuxfoundation.org/) and many other things
* [Itanium C++ ABI](http://refspecs.linuxbase.org/cxxabi-1.83.html)
* [Dwarf format](http://dwarfstd.org/)

### 异常处理/Exception Handling
* [Exception Handling](http://refspecs.linuxbase.org/abi-eh-1.21.html)
* [Exception Handling in LLVM](https://llvm.org/docs/ExceptionHandling.html)
* [A interesting post taught you how to implement C++ exception handling routines.](https://monoinfinito.wordpress.com/series/exception-handling-in-c/)
* [libc++abi](https://libcxxabi.llvm.org/)
* [libsupc++](https://gcc.gnu.org/onlinedocs/libstdc++/faq.html#faq.what_is_libsupcxx)
* [.eh_frame/LSDA](https://refspecs.linuxfoundation.org/LSB_3.0.0/LSB-PDA/LSB-PDA/ehframechpt.html)

### 汇编语言/Assembly Language
* [Ian Lance Taylor's blog](https://www.airs.com/blog/), has lots of good articles about linkers and loaders
* [GNU as docs](https://sourceware.org/binutils/docs/as/)
* [A x86 assembly reference](https://www.felixcloutier.com/x86/)
* [Another x86 assembly reference](http://ref.x86asm.net/)

