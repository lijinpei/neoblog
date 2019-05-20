---
title: C++虚表不完全指南
tags:
  - C++
---

## 介绍

作为一个想成为编译器工程师<del>抖M属性/杠精本精/吊代码不会写,吊语法扯一堆/语言律师</del>的男人,当然要征服一下C++ABI/object model.

C++ ABI/object model这个东西,我个人觉得也就3大块:

* object layout/function calling convention等C里面也有的东西.当然这里会涉及到引用类型/member pointer/name-mangling之类C里不存在的事情,不过如果不涉及vtable,事情基本上差不多.
* vtable/rtti
* exception handling

而在vtable/rtti/exception-handling之中,vtable是处在一个比较基础的位置.rtti显然需要vtable,exception-handling的catch在match类型的时候需要riit从而需要vtable. Exception-handling在控制流程,eh_frame之类事情在复杂程度上也是不及vtable的.

网上其他一些相关的资料包括:

Stanley Lippman的"inside C++ object model"那本书我没仔细看过,不予置评.

## Big Picture

vtable这个东西是用来出来虚函数调用,虚基类等问题的.我们先回顾一下vtable要解决的这个问题:

虚函数: A::B::C

虚基类: 

编译信息与运行信息

## 基础

primary base

primary virtual table

secondly virtual table

virtual table group

nearly vitual class 

两种size/alignment:

construction virtual table:

motivation

unique final overrider

complete object destructor

adjustor secondary entry points

vtable作用:

* 虚函数调用
* 访问虚基类
* rtti

同一个类可能有多个不同的虚表,当一个类A作为多个不同的类B1,B2,...,Bn的虚基类时,A in B1, A in B2, ..., A in Bn的虚函数表不同.

但是同一个most derived class的object的虚函数指针都指向相同的虚表.

address point of vtable:virtual-pointer并不是指向虚表的开头,而是指向虚表的某个特定位置,这个位置叫做address point.从而虚表中的项偏移可正可负.

## vtable的结构

按顺序分别为(不一定每一项都会在每个vtable中出现):

1. virtual call offset(等于不是define在自己中的虚函数的个数)
2. virtual base offet(等于虚基类的个数)
3. offset to top(1个)
4. typeinfo pointer(若`-fno-rtti`0个,否则1个)
5. virtual table pointer指向此处
5. virtual function pointers(虚函数数目减去primary base中虚函数个数)