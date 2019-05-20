title: Rust学习笔记
data: 2019-03-20
tags:
- Rust
---
## Borrow:
borrow/mutably borrow
## Copy:
默认"move semantics",如果一个类型实现了std::marker::Copy则"copy semantics".
copy和move都是bitwise的动作，不同的是对操作过之后变量的生命期的影响.

## Clone:
clone()是显式的动作.
若T:Copy，则T:Clone

## Drop:
drop()是隐式的动作,显式调用drop()是一个编译错误.但是可以std::mem::drop.
我本以为std::mem::drop()是一个buildtin,drop()的时候设置一个flag,在超出作用域的时候检查这个flag决定是否需要drop(),这个东西显然can not implemented as a library,不过这玩意儿的实现实际上不需要builtin

```Rust
#[inline]
#[stable(feature = "rust1", since = "1.0.0")]
pub fn drop<T>(_x: T) { }
```

那么问题来了，这个代码你怎么办:

```Rust
fn main() {
    let b = std::env::args().count() > 0;
    let s = "hello".to_string();
    if b {
        std::mem::drop(s);
    }
    if !b {
        println!("{}", s);
    }
}
```

答案是Rust拒绝接受这个代码(编译报错),由此可见，Rust编译器有点愚蠢/比较保守/分析不精确/error on the safeside/有些分析是基于region(scope))的.

等一下,基于region/scope,并不是所有的CFG都有Region结构的,如果你呆在Dijkstra的Structured Programming框架内,那么所有的CFG均reducible,可以划分region,但是如果有goto呢?嗯，我查了一下[Rust没有goto](https://mail.mozilla.org/pipermail/rust-dev/2014-March/009145.html)，好吧.

另外drop的时候是不能返回一个Result之类的，这就意味着drop的时候出错了就只能panic!(),此时会unwind触发更多drop(),很容易就double panic导致abort().

## Minutiae
以上是big picture，下面说一些细枝末节:

1. immutable reference:Copy + Clone, mutable reference: !Copy + !Clone.(这个稍微想一下就应该是这样的,因为reference borrwoing rule)
```Rust
// Shared references can be copied, but mutable references *cannot*!
#[stable(feature = "rust1", since = "1.0.0")]
impl<T: ?Sized> Copy for &T {}
```
2. 当使用derive自动实现Copy,Clone时，会自动把这些triat bound加到type parameter上.

关于2，我想找一个这样的例子: C1<T> where C1<T>: Copy, T: !Copy. 我现在想到的是immutable borrow,不过我可能需要一个更有说服力的例子.TODO

### 和C++的区别

### Clone需要一个lang_item

TODO

## Send与Sync

定义:
- T:Send当且仅当T在不同线程间copy/move是安全的
- T:Sync当且仅当&T:Send

首先,rust里

1. mut是binding的性质不是type的性质.下面的代码不编译:
```Rust
fn main() {
    let b:Box<mut i32> = Box::new<1>;
}
```
2. &mut是一个整体(同理*mut),不是mut modifier作用于&.

然后[Huon提到了两种情况](http://huonw.github.io/blog/2015/02/some-notes-on-send-and-sync/)

1. `Sync + Copy` => `Send`
2. `&mut T: Send` when `T: Send`

关于1.比较好理解；关于2.可能会问的一个问题是,&mut T transfer到另一个线程的时候,lifetime怎么办,答案是,讨论Send的时候假设transfer(这个假设也没有引起矛盾)

然后我在考虑这一点:

- T:Sync(等价于&T:Send)，当且仅当&T
    - 无interior mutability.
    - 或有atomic interior mutability
- T:!Sync,当且仅当&T有non-atomic interior mutability(或者叫non-multi-thread-safe interior mutability)

或者说，T:!Sync,当且仅当你在一个线程拿到一个&T后
- 此时，按照rust得borrow rule，其他线程最多能拿到&T
- 而从&T可以对数据进行不安全(non-atomic)的interior mutate(写)

再换句话说:data-race产生的条件是:
- 两个或以上并发操作未sync
- 其中一个操作为写

再再换句话说,T:Sync当且仅当&T不会产生data-race

这个规则可以正确处理
 - &T,&mutT: &&T和&&mut T均无interior mutability,从而它们Sync
 - Cell/RefCell/UnsafeCell
 - Rc<T>:Rc<T>对T本身无interior mutability,但是对引用计数的操作是data-race
 - Arc<T>:无data-race
 - Box<T>/Vec<T>:从&Box<T>或&Vec<T>只能拿到&T,你不能通过&Box<T>操作Box内部的指针,Vec<T>内部的指针,len,capacity所以&Box<T>/&Vec<T>是否data-race取决于&T是否可能data-race，从而却决于T是否Sync.
 - Mutex<T>和RwLock<T>:Rust里的Mutex和RwLock实际上是一个in-struct的T和一个指向posix锁的unique_ptr(unix上如此,windows上的实现嘛LOL).
 ```Rust
#[stable(feature = "rust1", since = "1.0.0")]
pub struct Mutex<T: ?Sized> {
    // Note that this mutex is in a *box*, not inlined into the struct itself.
    // Once a native mutex has been used once, its address can never change (it
    // can't be moved). This mutex type can be safely moved at any time, so to
    // ensure that the native mutex is used correctly we box the inner mutex to
    // give it a constant address.
    inner: Box<sys::Mutex>,
    poison: poison::Flag,
    data: UnsafeCell<T>,
}
 ```
 ```Rust
 pub struct Mutex {
    lock: AtomicUsize,
    held: UnsafeCell<bool>,
}
 ```
```Rust
#[stable(feature = "rust1", since = "1.0.0")]
pub struct RwLock<T: ?Sized> {
    inner: Box<sys::RWLock>,
    poison: poison::Flag,
    data: UnsafeCell<T>,
}
```
```Rust
pub struct RWLock {
    inner: UnsafeCell<libc::pthread_rwlock_t>,
    write_locked: UnsafeCell<bool>, // guarded by the `inner` RwLock
    num_readers: AtomicUsize,
}
```
首先，这俩玩意儿都不能提供额外的Send:
```Rust
#[stable(feature = "rust1", since = "1.0.0")]
unsafe impl<T: ?Sized + Send> Send for Mutex<T> { }
#[stable(feature = "rust1", since = "1.0.0")]

```
```Rust
#[stable(feature = "rust1", since = "1.0.0")]
unsafe impl<T: ?Sized + Send> Send for RwLock<T> {}
```
原因很简单，mutex/rw_lock被transfer(move)到另一个线程以后，全世界只有这一个新的线程有锁(有锁的地址,posix锁是通过地址区分的),你自己再怎么操纵自己的锁都不能跟其他线程同步来避免data-race(不过mutex至少没有带来额外的data-race的机会，所以当T:Send时,mutex依然是Send的).
然后似乎这样Mutex<T>应该是Sync的,因为&Mutx<T>操纵的是统一把锁,即使有Interior mutability,也会通过锁进行sync操作.我想了一下，能想出的反例是,T是一个实现为thread-local,并且T的语义也是thread-local的,对于Mutx<Rc<T>>这个例子，由于通过&Rc<T>可以进行clone而脱离LockGuard的保护，所以也不是安全的.

