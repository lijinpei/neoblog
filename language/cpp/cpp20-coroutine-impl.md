title: C++20 Coroutine的实现:别问，问就状态鸡
date: 2019-04-05
tags:
 - C++
 - coroutine
 - clang
 - llvm
---
C++20的Coroutine现在有MSVC和clang/llvm的实现，MSVC的实现我们看不到，clang/llvm的实现除了被C++利用外，也被Rust利用实现[coroutine](https://github.com/rust-lang/rfcs/blob/master/text/2033-experimental-coroutines.md)和[async](https://github.com/rust-lang/rfcs/blob/master/text/2394-async_await.md)。此外C++里还有boost实现的stackfull coroutine，boost里有已废止的[coroutine](https://www.boost.org/doc/libs/1_69_0/libs/coroutine/doc/html/index.html), [coroutine2](https://www.boost.org/doc/libs/1_69_0/libs/coroutine2/doc/html/index.html), [context](https://www.boost.org/doc/libs/1_69_0/libs/context/doc/html/index.html).其中coroutine2是在context上实现的,context本身在context switch上有u_context, f_context, win_fiber三种机制，以及若干种stack allocation机制.这篇博客会总结一下llvm和boost实现coroutine的机制.

上一篇博客里我说std::experimental::coroutine_handle是magic，这篇博客里我们来看看[magic是怎么实现的](https://clang.llvm.org/docs/LanguageExtensions.html#c-coroutines-support-builtins).

## llvm coroutine

### Big Picture

1. clang/Rust这些前端emit的LLVM IR里会包含某些coroutine相关的llvm intrinsics(llvm.coro.*).clang和Rust为coroutine emit的IR大概如下所示.
2. llvm负责把这些intrinsics lower到真正可以执行的machine code.对于每个coroutine，llvm会lower到一个frame struct(用来保存coroutine的状态)和三个函数: ramp,resume,destroy，如Gor 2016年11月llvm devmtg演讲里所示:
3. 此外还有devirtualization, heap elision等优化.

### llvm.coro.* intrinsics: 前端如何eimt IR
所有coroutine相关的llvm intrinsics名字都是llvm.coro.*的形式.首先，某些intrinsics会lower到真正的代码或者数据结构,比如coro.destroy, coro.resume；而且它一些intrinsics不lower到真正的代码或数据结构，它们在lower过程的最后会直接被去掉，它们只是起在lower的过程中记录一些新的的作用，比如coro.id这个intrinsics，我们没必要（也没有办法去）问这个intrinsics是怎么实现的.

#### <span>llvm.coro.id</span>
我们先拿core.id这个intrinsics开刀，这就是一个只记录信息，不lower到代码的intrinsics:
```llvm
declare token @llvm.coro.id(i32 <align>, i8* <promise>, i8* <coroaddr>, i8* <fnaddrs>)
```
首先,这个intrinsics的返回值是[token类型](https://llvm.org/docs/LangRef.html#token-type).这个类型的作用是把某些需要关联起来的指令关联起来，比如异常处理相关的catchswitch, catchret, catchpad.某些指令A的返回值是token类型（token def）,某些指令B会接受token类型的参数(token use)，除此之外没有任何任何能对token做的事情,不能jump到token(label类型做这个事情的),每个token use肯定是token常量(你没法对token做def/use以外任何事情，搞不出来token变量),所以用token关联起来的指令间的关系也是编译时可以确定不变的.

对于coro.id来说，返回的这个token标记了core.id出现在其中的那个coroutine(LLVM要求每个coroutine中有且只能有一个<span>coro.id</span> intrinsics).

<span>coro.id</span>的第一个参数必须是常量，记录了coroutine frame allocation的alignment;第二个参数如果非null,那么作为参数的那个值是这个coroutine的promise(promise是用来在coroutine suspend/resume之间传递参数的内存区域/类型).第三个参数，前端(clang/Rust)emit LLMVM IR的时候填0，CoreEarly pass会在这里存函数指针.第四个参数在coroutine split之前为0，之后指向一个存放resume, destroy函数的global constant array.

所以这个指令完全是记录信息用的,不要问这个指令是怎么实现的这种问题.

#### <span>llvm.coro.size</span>

```llvm
declare i32 @llvm.coro.size.i32()
declare i64 @llvm.coro.size.i64()
```
这个指令返回coroutine frame的大小(这个信息显然编译器是知道的)。我有一些问题的一点是这个指令lower到一个常数，但是这一点没有在llvm.core.size的类型信息中反映出来。

#### <span>llvm.coro.begin</span>和<span>llvm.coro.free</span>
```llvm
declare i8* @llvm.coro.begin(token <id>, i8* <mem>)
```
```llvm
declare i8* @llvm.coro.free(token %id, i8* <frame>)
```
llvm.coro.begin只能有且只有一个.
llvm.coro.begin和llvm.coro.end不是一对CP，真正的好基友是llvm.coro.begin和llvm.coro.free。这俩指令的第一个参数都是llvm.coro.id返回的token。coro.begin的第二个参数<mem>是已经开辟好的(我们coro.size获取了需要开多大地址)用来存放coroutine frame的内存地址,他返回coroutine frame在<mem>中的地址，coro.free的第二个参数是coroutine frame的地址，它返回相应的<mem>的地址.出于alignment的考虑<mem>和<frame>可能之间差了一个常量，这两个指令是用来在两个地址之间做调整的.

这俩指令配合有两个作用:
 1. <mem>和<frame>之间出于alignment考虑可能存在偏移量
 2. heap allocation elision

#### <span>llvm.coro.alloc</span>

这里有一个问题，为啥llvm.coro.begin和llvm.coro.free需要一个token参数?毕竟这俩指令出现在哪里肯定隐式地就是处理哪个coroutine。原因是:
### Coroutine变换pass: llvm如何实现coroutine

Shape
LowerBase
### 资料来源

- [llvm coroutine docs](https://llvm.org/docs/Coroutines.html)
- [Gor 2016-11 llvm devmtg演讲](https://llvm.org/devmtg/2016-11/Slides/Nishanov-LLVMCoroutines.pdf)

## boost context

## mcontext_t/u_context_t, sigreturn与SROP

https://thisissecurity.stormshield.com/2015/01/03/playing-with-signals-an-overview-on-sigreturn-oriented-programming/

https://lwn.net/Articles/676803/
