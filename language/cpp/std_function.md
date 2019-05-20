---
title: `std::function`占用多少个字节?
date: 2019-05-11
tags:
  - C++
---

在一个月黑风高的晚上,我突然想知道std::function占用多少个字节.

我试了一下,答案是32个字节:

```C++
#include <functional>
#include <iostream>

int main() {
  std::function<int()> f;
  std::cout << sizeof(f) << std::endl;
}

// g++ && ./a.out
```

而且我看了一下代码,所有std::function的特化均为32个字节.

## 为什么不是8字节?

8字节是x86_64架构指针的大小.std::function不是8字节是因为pointer-to-member-function[需要16个字节](http://lazarenko.me/wide-pointers/).

## 为什么不是16字节?

std::function本身是erase掉functor的类型的,但是std::function的接口中有一个target_type()函数:
```C++
target_type std::function
 
获得 std::function 所存储的目标的typeid 
(公开成员函数)
```
所以我们至少需要另外8字节的等效的type_info指针,注意这里不是直接存了一个指向type_info的指针,而是存了一个Manager对象的指针,通过Manager指针可以找到type_info.

## 为什么不是24个字节?

然而事情到这里还没有结束,pointer-to-member-function和普通函数指针在调用时在abi方面是不同的:

* 一个16字节,一个8字节,不可能调用时需要的指令相同
* pointer-to-member-function需要调整this,普通函数调用时不需要调整参数

所以我们还需要一个`invoker`,来调用我们保存的指针,这个invoker指针其实是可以通过`Manager指针`得到的,因为`Manager指针`含有functor的类型的信息,理论上他是可以知道怎么根据指针调用普通函数或者member的.

但是这样做有效率方面的问题,因为省掉invoker指针后,无非两种做法:

* Manager对象有个invoke虚方法
* Manager对象现在的实现中有一个初入operation枚举,进行相应操作的方法.可以添加一个获取invoker指针的枚举项.

但是std::function的`operator()`应该是我们比较在意时间开销的一个操作,上面这两个方法,前者多一次indirection,后者多一次函数调用,所以实现上还是选择多一个invoker成员减少std::function的调用开销.

## 有没有可能24个字节且开销比较小?

其实还是有的.

改进1:让Manager在收到invoker operation的时候不是返回invoker指针,而是直接进行调用.这样的问题是std::function的operator()的参数和Manager的参数不(一定)相同,Manager需要variadic,而x86_64上variadic函数调用要用栈传参,得不偿失.

改进2:Variadic且按正常方式寄存器传参,这个方法用C的那一套vararg是不行的.可能的一个做法是大概这样:

```C++
enum operation {
  op1,
  op2,
  op_invoke
}

// mp1和mp2是manage操作需要的参数
struct mp1 {
};

struct mp2 {
};

// cp是invoke操作需要的参数
struct cp {
};

// 和原来的Manager函数参数相同
void manager_impl(mp1 p1, mp2 p2) {
}
void invoke(cp p) {
}

void Manager(operation op) {
  if (__likely__(op == op_invoke)) {
    reinterpret_cast<void(*)()>(invoke)();
  } else {
    reinterpret_cast<void(*)()>(manager_impl)();
  }
}

std::function<void(cp)>::operator()(cp p) {
    reinterpret_cast<void(*)(operation, cp)>(manager)(op_invoke, p);
}
```
这样可能会干涉寄存器分配.
