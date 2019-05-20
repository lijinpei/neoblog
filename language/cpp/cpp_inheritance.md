title: C++ Object Model
date: 2019-04-20
tags:
 - C++
 - assembly
---
## 介绍
在这篇博客中，我会记录下自己对C++ Object Model的总结，主要包括以下几个方面:

- Object layout
- Virtual
- Exception

这篇博客的内容是关于Linux平台上gcc/clang对C++ ABI的处理，但是C++标准中并没有ABI相关的规定，所以这篇博客的很大一部分理论上都是architecture/platform specific implementation details，不过gcc/clang的处理方式是Linux平台上的de facto标准。这篇博客的内容不适用于MSVC或其他编译器。

## 参考标准

## 回顾一些C++语法

### POD/trival/standard-layout/nearly-empty-class/POD-for-the-purpose-of-layout

#### defaulted/implicitly-declared/implicitly-defined
这一部分和下一部分的内容大量参考了[Howard Hinnant的slides](https://www.slideshare.net/ripplelabs/howard-hinnant-accu2014)。在这里要感谢一下Howard Hinnant对special members，stack allocator的介绍，和对move semantics以及std::chrono做出的贡献。

C++中有6个special members:

- default constructor
- destructor
- copy/move constructor
- copy/move assignment operator

它们special的地方在于，在某些情况下，编译器会为我们declare/define它们。具体哪些情况，规则比较复杂，请参考Howard Hinnant的slides或者下一部分的内容。

用户可能declare/不declare某个special member,编译器可能declare/不declare某个special member，排除掉用户declare且编译器declare这种不可能出现的情况，所以，共有三种可能:

- not declared: 用户没有declare，编译器认为不满足declare的条件，也没有declare。
- implicitly declared: 用户没有declare，编译器认为满足declare的条件，编译器dealcre。
- explicitly declared: 用户declare，编译器就不会再implicitly declare了。

default/defaulted special member可以是implicitly defined或

而对于define的情况，not-declared显然不会有definition，implicitly declared可能会有default-definition或者deleted-definition，explicitly-declared除了可以是default-definition和deleted-definition之外，还可以是user-definined。

此外，还有一个概念叫做user-provided。对于一个defined-member,要求是user-provided的条件是:

1. user-declared
2. in-class declaration不是`= default`的形式

换句话说

1. 如果你显式写了member的function body的花括号`{}`，哪怕你的default-ctor的body只有花括号(implicitly-defined default-ctor的行为和empty-body, empty-initializer-list的default-ctor的行为一样)，那么也算是user-provided.
2. 如果你显式写的实现是`= default`

    2.1 `= defult`出现在in-class declaration处，那么*不为*user-provided.
    ```C++
        struct Foo {
            Foo() = default;
        };
    ```
    2.2 `= defult`出现在out-of-class definition处，那么*为*user-provided.
    ```C++
        struct Foo {
            Foo();
        };
        Foo::Foo() = default;
    ```

implicitly-declared special member只有odr-use的时候才可能被define.

注意，default-ctor的定义是可以不带参数调用的ctor，也就是说,template-ctor或者全部parameter都有default-argument的ctor都是default-ctor,不可以是variadic?。但是copy/move ctor/assignment的定义是必须那种特定signature的member,从而包括了template-member排除了有defualt-argument的member。dtor当然无法重载/templated。

dtor与virtual。

implicitly-declared special member可能为deleted，例如，可能由于以下这些情况:

implicitly-declared special member的exception specifier.

implicitly-declared special member的cv specifier.

implicitly-declared copy ctor/assignment的参数

注意not-declared与delete的区别:
- not-declared不会影响name-lookup进而不会影响overload resolution。
- delete会使name-lookup停止到这里，进而影响overload resolution。

我认为定义为private和delete区别不大(当然除了对class自身的代码)。

object representation/value representatin

An implicitly-declared special member function is declared at the closing}oftheclass-specifier. Programs shall not define implicitly-declared special member functions.

potentially constructed subobjects(reference?)

### virtual function与inheritance

#### virtual function

##### Rust Object Safety

#### virtual inheritance

### access control

#### member access specifier

#### base access specifier

## virtual

## exception