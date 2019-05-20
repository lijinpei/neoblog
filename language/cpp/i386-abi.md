title: x86 abi学习总结
date: 2019-04-10
tags:
  C/C++
  assembly

# x86 abi学习总结

## variadic function实现
这个问题之前有一次校招面编译器岗位的时候面试官问我了。我觉得这个问题的特点是，如果没有一点背景知识的话，可能都不知道面试官问的啥。我当时就是不知道面试官问的点是啥，我当时连va_start那几个宏的用法都不记得了，然后忽悠了面试官一下, shame on myself.

### i386传参约定

### x86_64传参约定

### variadic传参约定

## asmlinkage

asmlinkage是系统调用的传参约定，前面我们说的传参约定是gcc/clang编译“普通”函数时候的传参约定.

当我第一次看到linux内核中，[i386平台asmlinkage的定义的时候](https://elixir.bootlin.com/linux/v5.0/source/arch/x86/include/asm/linkage.h#L11)，
```C
#ifdef CONFIG_X86_32
#define asmlinkage CPP_ASMLINKAGE __attribute__((regparm(0)))
#endif /* CONFIG_X86_32 */
```
我的反应是,WTF，是我脑子抽了还是写内核的人脑子抽了(当然，大概率是我)，i386的默认传参约定不就是regparm(0)吗?然后我(费了些周折地)查了一下，明白了为啥。然后几个月过去之后，我能记起来的只是，emm......我知道关于i386 asmlinkage有一些值得注意的点，但是我不记得具体是啥了.所以我觉得写技术博客的一个好处就是,可以帮我回忆过去学过的东西。当然，另一个好处是不断提醒我有很多我还没学的东西。

然后回到这个问题是，答案是，[内核在i386平台上编译的时候，内部使用了不同于用户空间的传参约定](https://stackoverflow.com/questions/31920857/calling-convention-regarding-asmlinkage)。

## NRVO

从abi/函数传参约定的角度看,RVO/NRVO是一件很自然的事情.可以看这个[cppcon](https://www.youtube.com/watch?v=IZbL-RGr_mk)或[cppnow](https://www.youtube.com/watch?v=fSB57PiXpRw)视频(他们都只有5分钟).

我也不知道为啥有俩几乎完全一样的cppcon,cppnow视频，也许人类的本质是复读机.

## C++ object layout: virtual-table/virtual-inheritance/thunk/rtti/dynamic-type/static-type

## C++ exception handling

## 资料来源