title: C++20 coroutine总结
data: 2019-04-04
tags:
  - C++
  - coroutine
---
## Coroutine是啥？能吃不？
C++20中进入标准的coroutine是stackless(或者叫suspend-up)，asymmetric coroutine方案.先解释几个术语:

stackless(等于suspend-up)/stackfull(等于suspend-down):

- stackless coroutine中，coroutine只给自己的frame分配了空间,从coroutine调用普通函数时，仍使用原来的函数栈(每个线程的函数栈)．所以，stackless coroutine无法在它调用的子函数中suspend．
- stackfull coroutine中,coroutine分配了完整的函数栈空间,从coroutine调用普通函数时，使用当前coroutine的函数栈.所以,stackfull coroutine，可以在子函数函数调用中suspend.

asymmetric/symmetric coroutine:
- asymmetric coroutine的suspend操作只能回到先前resume/create自己的地方.
- symmetric coroutine的suspend操作可以回到任何一个被suspend的coroutine那里.

C++20中coroutine是stackless asymmetric,其他的coroutine:

- goroutine是stackfull symmetric
- boost.context, boost.coroutine2均为stackfull symmetric
- scheme call/cc是stackfull symmetric
- scheme的continuation可以重复使用任意次,boost的continuation都是one-shut的，只能使用一次
- Rust的coroutine也是基于llvm做的,也是stackless asymmetric
- ES6的generator/async是stackless asymmetric

我不确定C++的coroutine方案是从哪里＂抄＂的，有可能是C#，但是我不确定.

## C++20 coroutine怎么搞啊?能干啥?<del>干起来爽吗？</del>
这一小节中我们来写几个简单的coroutine．

### 准备工作
想要玩C++20 coroutine的话，你需要一个支持coroutine-ts的toolchain，当前有MSVC 2015以后的版本和clang 5.0以上的版本提供了支持(C++20 coroutinｅ提案的作者Gor Nishanov就职于微软，最早实现这个coroutine提案的也是MSVC.后来Gor和他的同事们把实现port到了clang).我们不使用<del>邪恶轴心</del>M$的工具，而是使用<del>你最喜欢的编译器</del>clang来玩coroutine.[Gcc现在还没有coroutine支持](http://gcc.gnu.org/projects/cxx-status.html)，可以在这个[wiki](https://gcc.gnu.org/wiki/cxx-coroutines)检查gcc对coroutine的支持状态.可以在这里查看[clang对C++标准的支持情况](https://clang.llvm.org/cxx_status.html).

此外，coroutine需要标准库中某些设施的配套支持，libstdc++还没有提供这些支持，所以我们使用clang家的libc++，一般即使你从linux发行版安装了clang也不一定会安装libc++(libstdc++和libc++某种程度上可以互换，所以你最好检查一下安装了libc++)．下面的例子中我们使用coroutine-ts中的头文件路径<experimental/coroutine>，我没有去查C++20中这个头文件路径是啥(估计是<coroutine>)，反正现在各个toolchain也没支持C++20.

另外，clang开启coroutine特性需要-fcoroutines-ts编译选项，我们使用完整编译选项是:

```
clang++ -fcoroutine-ts -stdlib=libc++ -std=c++17
```
安装好clang和libc++以后，可以用这段代码检查一下是否准备就绪:
```C++
#include <iostream>

#if defined(__cpp_coroutines)
#include <experimental/coroutine>
#include <type_traits>

template <typename T>
void output_size() {
  std::cout << sizeof(T) << std::endl;
}

struct my_generator {
  struct promise_type;
};

namespace coro_ns = std::experimental;

int main() {
  output_size<coro_ns::suspend_never>();
  output_size<coro_ns::suspend_always>();
  output_size<coro_ns::coroutine_handle<int>>();
  output_size<coro_ns::coroutine_handle<void>>();
  std::cout << std::boolalpha << std::is_same_v<my_generator::promise_type, coro_ns::coroutine_traits<my_generator>::promise_type> << std::endl;
}

#else
int main() {
  std::cout << "no coroutine support found" << std::endl;
}
#endif
```
检查编译test.cpp可以成功:
```
clang++ -std=c++17 -stdlib=libc++ -fcoroutines-ts 1.cpp
```

如果:
- 编译成功，有相应输出，那么你可以接着看下面的内容
- 编译成功，输出"no coroutine support found"，检查一下你是不是使用的合适的clang版本，并给了-fcoroutine-ts选项
- 编译失败，找不到头文件<experimental/coroutine>，检查一下你是否安装了libc++，是否给了-stdlib=libc++选项

下面让我们的第一个coroutine，一个generator:

```C++
#include <experimental/coroutine>
#include <iostream>

namespace coro_ns = std::experimental;

template <typename T>
struct my_promise; 

template <typename T>
class my_generator;

template <typename T>
struct my_promise {
  T current_value;
  my_generator<T> get_return_object() {
    return my_generator<T>(coro_ns::coroutine_handle<my_promise>::from_promise(*this));
  }
  auto initial_suspend() {
    return coro_ns::suspend_always{};
  }
  auto final_suspend() {
    return coro_ns::suspend_always{};
  }
  void unhandled_exception() {
    std::terminate();
  }
  void return_void() {}
  auto yield_value(const T&v) {
    current_value = v;
    return coro_ns::suspend_always{};
  }
};

template <typename T>
class my_generator {
public:
  using promise_type = my_promise<T>;
  T& operator()() {
    return handle.promise().current_value;
  }

  operator bool() {
    return !handle.done();
  }

  void* address() {
    return handle.address();
  }

  ~my_generator() {
    handle.destroy();
  }

  my_generator& operator++() {
    handle.resume();
    return *this;
  }

private:
  friend struct my_promise<T>;
  using handle_type = coro_ns::coroutine_handle<promise_type>;
  handle_type handle;
  my_generator(handle_type h): handle(h) {}
};

my_generator<int> sequence(int from , int to) {
  for (; from < to; ++from) {
    co_yield from;
  }
}

my_generator<uint64_t>  fibonacci() {
  uint64_t a = 1, b = 1;
  while (true) {
    co_yield a;
    co_yield b;
    a += b;
    b += a;
  }
}

int main() {
  my_generator<int> c1 = sequence(0, 20);
  while (++c1) {
    std::cout << c1() << ' ';
  }
  std::cout << std::endl;
  my_generator<uint64_t> c2 = fibonacci();
  for (int i = 0; i < 20; ++i) {
    std::cout << (++c2)() << ' ';
  }
  std::cout << std::endl;
}

```
在这个例子中我们展示如何创建coroutine，如何从coroutine中suspend/resume．这个例子中涉及几个概念，在下面的正式介绍中，我们会抽象地提到这些概念，如果你需要具体一的东西帮助理解，你可以回过头来看这些例子．

- coroutine:在这个例子中就是sequence,fibonacci．他们看上去像普通函数差不多，除了在他们的body中使用了co_return/co_await/co_yield关键字(粗略地说，想做语言律师的话下面有专门的语言律师小节)．这些函数的body定义了coroutine如何运行:ramp(create)/suspend/resume/return.这些函数的返回值类型我们叫做R.
- R: coroutine的返回值类型我们用R来表示，例如这里的generator<T>．注意，R并不是由co_return e中的ｅ推导的，coroutine的返回值类型也不能写个auto让编译器来推导.因为这个R是你告诉编译器的输入，编译器根据R来决定coroutine在方方面面的行为，所以R:

  1. 必须由程序员提供
  2. 不能为auto，不可以从co_return推导.

- promise_type:每一个R类型都有一个关联的promise_type，下面正式介绍中会讲如何从R找到promise_type.这个promise_type的大致作用,promise_type是真正决定coroutine方方面面行为的类型(R决定了promise_type,promise_type决定了coroutine的行为)，例如初始和结尾的suspend,如何await/yield,如co_return(重复一下,R决定了promise_type决定如何co_return，所以不能从co_return推导R)，如何处理异常，如何allocate/deallocate coroutine的frame.R和promise_type的区别在于，R是外部调用coroutine的creator得到的操纵coroutine的类型，而从coroutine的调用者那里直接看到的不是promise_type.
- awaiter:awaiter类型是可以co_await的类型(粗略地说,下面的正式介绍中会有详细说明)，例如这里的suspend_never, suspend_always．他们定义了coroutine在await一个表达式时的行为:例如你await一个异步网络IO操作,awaiter决定了当前IO是否已经完成，没完成的话是否把当前coroutine suspend,suspend以后何时resume(决定何时resume这个类似Rust futures v1中的waker参数,上面的例子中没有展示这个功能).上面的例子中没有显示的co_await，但是co_yield是用co_await定义(co_await是coroutine中比较基本的操作,co_yield，co_return和co_await range for statement都是用co_await定义的).
- coroutine_handle:上面四个类型和coroutine_traits都是用户自定义的类型,这是coroutine-ts中唯一一个不是/不允许/不能让用户定义来自定义coroutine行为的类型，coroutine_handle暴露了如何resume coroutine，询问coroutine是否suspend在最终suspend点等操作.下一篇博客会接受C++20 coroutine是如何在clang中实现的，到时候我们会看到coroutine_handle在libc++中的实现以及如何写C语言的coroutine(提示:compiler intrinsics).

在正式介绍C++20 coroutine之前，我们再看两个例子，例2展示了如何向coroutine传递值.

这个例子展示了coroutine的调度，这个例子只在linux平台下工作.

## 正式介绍

### 三个新关键字
C++20中增加了以下关键字：
```
co_await
co_yield
co_return
```
一个＂函数＂，如果函数体中出现了这些关键字，那么这个"函数"就是一个coroutine，如标准中给出的例子:
```C++
task<int> f();
task<void> g1() {
int i = co_await f();
std::cout << "f() => " << i << std::endl;
}
template <typename... Args>
task<void> g2(Args&&...) { // OK: ellipsis is a pack expansion
int i = co_await f();
std::cout << "f() => " << i << std::endl;
}
task<void> g3(int a, ...) { // error: variable parameter list not allowed
int i = co_await f();
std::cout << "f() => " << i << std::endl;
}
```
这里g1,g2,g3都是coroutine因为他们的函数体中使用了相关的关键字.

### 控制流的转移:promise，coroutine返回类型和coroutine_handle
令R表示coroutine的返回类型(如上面的task<void>),P1到Pn表示coroutine的参数(non-static class member 会把this pointer作为第一个参数)．标准中引入了一个类模板coroutine_traits：
```C++
coroutine_traits<R, P1, ..., Pn>
```
coroutine_traits(以下我们用T来表示)是让用户来偏特化，从而控制coroutine的行为的，具体的控制方法是:

coroutine_traits应该有一个promise_type类型成员
```C++
T::promise_type
```
令F表示coroutine的body，标准中coroutine表现得如同它的body是：
```C++
{
  P p;
  co_await p.initial_suspend(); // initial suspend point
  try { F } catch(...) { p .unhandled_exception(); }
  final_suspend :
  co_await p.final_suspend(); // final suspend point
}
```
也就是说，会为coroutine默认构造一个它的promise_type对应的promise object，而调用coroutine的地方得到的，其实是类型R的object，而R和promise是如何建立起来联系的呢?比如你有Ｎ个coroutine(和编译器隐式为你创建的promise type)，和N个coroutine handle(每次调用coroutine的返回类型)，r和ｐ怎么知道自己对应的ｐ和ｒ呢?答案是:coroutine调用返回的r是通过p.get_return_obect()创建的，这样p就可以在自己的member function里把r和自己联系起来. 相应的`initial_suspend()`,`unhandled_exception()`,`final_suspend()`方法决定了coroutine在相应情况下的行为．
表达式中增加了await表达式.此外根据P中是否定义了`return_void`或`return_value`(最多只能定义一个)决定当从coroutine的body flow off时相当于`co_return;`还是UB.

我个人非常愿意把R叫做coroutine handle类型，只不过标准已经定义了一个`coroutine_handle<promise_type>`(所以我不能把R叫做coroutine handle/handler类型，我不想把水混).这个coroutine_handle和R, promise_type，coroutine_traits不同之处在于，coroutine_handle不是让你(库的作者）来定义的,之前提到的三个类型都是让库的作者来定义(我觉得正常人不会愿意每天处理这么麻烦的东西),从而调整coroutine的行为的，而这个coroutine_handle是语言提供给你的magic(你无法自定义也自定义不出来这样的效果),我们来看一下这个coroutine_handle的接口:

```C++
namespace std {
namespace experimental {
inline namespace coroutines_v1 {namespace std {
namespace experimental {
inline namespace coroutines_v1 {
template <>
struct coroutine_handle<void>
{
// 18.11.2.1 construct/reset
constexpr coroutine_handle() noexcept;
constexpr coroutine_handle(nullptr_t) noexcept;
coroutine_handle& operator=(nullptr_t) noexcept;
// 18.11.2.2 export/import
constexpr void* address() const noexcept;
constexpr static coroutine_handle from_address(void* addr);
// 18.11.2.4 observers
constexpr explicit operator bool() const noexcept;
bool done() const;
// 18.11.2.5 resumption
void operator()();
void resume();
void destroy();
private:
void* ptr; // exposition only
};
template <typename Promise>
struct coroutine_handle : coroutine_handle<>
{
// 18.11.2.1 construct/reset
using coroutine_handle<>::coroutine_handle;
static coroutine_handle from_promise(Promise&);
coroutine_handle& operator=(nullptr_t) noexcept;
// 18.11.2.3 import
constexpr static coroutine_handle from_address(void* addr);
// 18.11.2.6 promise access
Promise& promise() const;
};
} // namespace coroutines_v1
} // namespace experimental
} // namespace std
```
首先,coroutine_handle可以默认构造，但是默认构造出来的coroutine_handle并没有关联的coroutine，你并不能对它干啥.如果你想对coroutine_handle干啥，你需要从promise_type构造一个coroutine_handle，然后这个coroutine_handle就和这个coroutine，这个coroutine_promise关联起来来了,这就是语言和运行时提供给你的magic．然后，这个coroutine_handle还有一个神奇的`resume()`方法,调用它就能转移到被suspend的coroutine那里:
```
只要记住你的名字
不管你在世界的哪个地方
我一定会，去见你。
——新海诚《你的名字》
```
```
只要握紧你的coroutine_handle
不管你suspend到那个地方
我一定能,resume到你
——LJP《C++ Coroutine总结》

```
```
名字一旦被夺走，就再也找不到回家的路了。
——宫崎骏《千与千寻》
```
```
<del>
coroutine_handle一旦被夺走，就再也找回到resume的路了．
——LJP《C++ Coroutine总结》
</del>
```

(这个其实是不对的,coroutine_handle不和coroutine的life-time关联)
我们之前提到，调用coroutine的地方得到的R类型的变量是p.get_return_object()得到的.而我们在希望恢复coroutine的时候是调用r的某个方法，但是问题是,r是我们自定义的,r如何能恢复到p和p的coroutine，答案是:p.get_return_object()过程中,会用p初始化一个coroutine_handle,然后r就可以用这个coroutine_handle恢复到coroutine了.所以我们可以看到R是在coroutine_handle的基础上提供了更丰富的接口(以及resume时传给coroutine一个值，下面讲怎么做这件事情)，所以其实我非常想叫R coroutine handle，只不过这个名字已经被占用了,所以我就继续叫它R好了.

### 如何在suspend/resume之间传递值:co_await表达式
目前为止，我们搞清楚了这样一些事情:
- R是调用coroutine的地方得到的返回值,R中会存有指向promise_type的指针(其实非必要)和coroutine_handle,我们会调用R的方法恢复coroutine,R通过coroutine_handle将控制流转移到coroutine
- promise_type有一些成员方法定义了coroutine的行为.
那么如何在控制流转移的同时传递值给coroutine/从coroutine获取值呢?这个要从co_await表达式和co_await运算符说起:
```
await-expression:
co_await cast-expression
```
我们先忽略掉一些细节,保持在"主航道"（手动滑稽）.令a表示`co_await`后面的表达式（上面写的是cast-expression，我们先忽略这个cast，就把它当成一个表达式）,然后e是`operator co_await(a)`(事实上当没有这样一个operator的时候,e就是a,我们暂时忽略这一点,我们同时忽略掉了标准中的o和关于temporary object的细节)，然后e要能调用这样三个表达式:
```C++
e.await_ready()
e.await_suspend()
e.await_resume()
```
e.await_ready()和e.await_suspend()决定了是否在await时suspend当前coroutine,e.await_resume()是await表达式的值.在翻译标准中对这个await表达式求值的描述之前，我们先看个伪代码解释，这个伪代码解释是Gor 2015年写的N4402里的,C++20标准里并没有包含这个伪代码,我也没去找后来的文档中有没有更新一点版本的，不过我认为这个版本的伪代码就能说明问题.

我在这里想吐槽一下,2015年C++已经开始搞出来coroutine的实现了,而直到2019年这个实现才进标准，而某*ust语言从2015到2019提了一个futures v1的协程方案又废弃掉了,搞了futures v2好像从没见有谁用又搞出了个v3,虽然依赖v1的某*okio库已经成了这门语言的广泛应用的异步IO事实标准，C++虽然刷feature刷得慢(跟某ust比慢，跟过去的C++相比速度和数量已经起飞了)，但至少C++语言演进的工作流程是比较严谨稳健的.

如果我们用block语句的返回值表示await表达式的值，那么await表达式的求值可以描述为(我们忽略了await suspend表达式是void类型的情况):
```C++
{
  auto && __expr = cast-expression;
  if ( !await-ready-expr && await-suspend-expr) {
  suspend-resume-point
  }
  return await-resume-expr;
}
```
然后对照上面这个示意的伪代码，我翻译一下C++标准中对co_await表达式求值的描述:

await表达式先求值await-ready表达式,之后:
- 如果结果为false,coroutine被认为已经suspend.然后求值await-suspend表达式.
- 如果结果为true,

除了co_await表达式,co_return表达式的求值是比较简单的,基本上就是用co_return的操作数调用p的某个成员函数,然后停到最终suspend point.注意coroutine不能用return表达式，这其实只是一个规定，另外允许了只co_return不co_await/co_yield的coroutine.此外flowing off coroutine的函数体,当`p.return_void()`合法时相当于无操作数的co_return，否则是UB.(问题:再次从final suspend point恢复?)

co_yield表达式是用co_await表达式定义的，令e表示co_yield表达式的操作数,p表示coroutine的promise object,则co_yield表达式等价于:
```
co_await p.yield_value(e)
```


## 细节
co_await表达式可以出现的环境:
constexpr
不能是coroutine的东西
coroutine不能是variadic
get_return_object()
await_transform()
co_await temporary

## 相关C++草案

##"不相关"的C++草案
下列C++草案是关于coroutine的，但是或者不是关于已经进入C++20的coroutine方案的，或者是已经被毙掉的.

其他coroutine草案:

已经被毙掉的coroutine草案:

