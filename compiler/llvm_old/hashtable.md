# Hash Table

下面这些是关于哈希表的数据结构.

* DenseMap
* DenseSet
* DenseMapInfo
* Hashing
* StringMap


关于哈希表有三个方面需要考虑:

1. 这个哈希表类（模板）的contract是什么.
2. 如何计算一个类型的哈希值.
3. 哈希表自身的实现策略.

所谓contract,无非

* 使用这个哈希表的类(KeyT/ValueT)需要满足什么条件(例如movable/copyable/default-constructbale).
* 调用哈希表的方法时的precondition/postcondition/side-effect/时间空间的复杂度
* 实现者如何操纵用户提供的类
* 用户如何操纵实现者的哈希表

换句话说，就是使用者需要施加什么样的约束(使用者对实现者的保证)，又能从实现者那里获得设么样的保证;实现者能从使用者那里获得什么样的保证，自己又能对使用者提供什么样的保证.这其实是一件很简单自然直白的事情．

关于如何计算一个KeyT的哈希值.计算一个好的哈希值是一个本身值得单独讨论的数学问题，而且这个问题是正交于＂给你一个哈希函数(无论好坏),如何使用这个哈希函数组织哈希表＂这个问题.LLVM ADT并没有从数学的角度帮你设计一个好的哈希函数，而只是提供了一些(工程上)方便你实现哈希函数的工具．

问题3是关于哈希表本身open addressing/separate chaining, rehash策略, 碰撞处理策略,cuckoo哈希等.

这篇短文将从上面三个方面介绍LLVM中的哈希表.

## Hash Table的接口

## Hash Key的计算

## Hash Table的组织

### Epoch

        [DebugEpochBase](http://llvm.org/doxygen/classllvm_1_1DebugEpochBase.html)和[llvm::DebugEpochBase::HandleBase](href="http://llvm.org/doxygen/classllvm_1_1DebugEpochBase_1_1HandleBase.html").哈希表当rehash/rebucket发生时，会invalidate掉旧的iterator，为了帮助调试这类误用invalid iterator的错误，考虑这样:

* 为哈希表增加一个int型变量epoch
* 当rehash发生时，inc epoch;</p>
* 为每个hash_table::iterator增加一个int型变量epoch,记录创建这个itor时哈希表的epoch值;</p>
* 当使用itor访问哈希表时,assert(itor.epoch == hash_table.epoch);</p>
* DebugEpochBase和DebugEpochBase::HandleBase就factor out了这部分功能，你的容器和迭代器需要继承这两个类，在合适的时间调用操作epoch的方法.这两个类的定义均conditiond on LLVM_ENABLE_ABI_BREAKING_CHECKS这个宏，没定义这个宏时相应操作为nop．目前DenseMap和SmallPtrSet使用了这个功能.

        对于这三个问题的解答:
        <p> 1. LLVM提供了hash_combine，你不再需要直接根据你的类型的成员变量计算出哈希值,你只用使用hash_combine来表达，例如:根据长度len, 和指针的地址ptr来计算哈希值;或者根据指针ptr指向的位置及其后面len个字节的内容来计算哈希值.这样做的好处是，设计一个好的哈希函数是一件困难，并且实现起来容易出错的事情，你并不希望每天都要做这种工作，但是指定某个类型的哪些数据成员构成哈希函数的输入是一件简单，不容易出错，并且与哈希函数的设计解耦合的一件事情.这部分功能也是一个新的C++提案<a href="http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2012/n3333.html">N3333</a>.你可以阅读<a href="http://llvm.org/doxygen/Hashing_8h_source.html">Hashing.h</a>的注释来了解更多内容.
        <p> 2. DenseMap的第二个模板类形参是<a href="https://github.com/llvm-mirror/llvm/blob/ae1ca02d148ec1e591d38a71f429b4804a07f638/include/llvm/ADT/DenseMap.h#L643">KInfoT</a>，默认为DenseMapInfo&lt KeyT&gt ,这个类应该提供如下<a href="https://github.com/llvm-mirror/llvm/blob/ae1ca02d148ec1e591d38a71f429b4804a07f638/include/llvm/ADT/DenseMapInfo.h#L29"> static方法</a>，DenseMap通过这个traits类来操纵KeyT，你可以特化/偏特化DenseMapInfo，或者给DenseMap传入其他的traits来自定义DenseMap.</p>
        <p> 3. 这个哈希表相关的数据结构，均为open addressing(也即，bucket直接存在<a href="https://github.com/llvm-mirror/llvm/blob/ae1ca02d148ec1e591d38a71f429b4804a07f638/include/llvm/ADT/DenseMap.h#L653">数组</a>中，而不是另外存在linked-list中);rehash实现在<a href="https://github.com/llvm-mirror/llvm/blob/ae1ca02d148ec1e591d38a71f429b4804a07f638/include/llvm/ADT/DenseMap.h#L728">这里</a>，除了reserve外的rebucket策略在<a href="https://github.com/llvm-mirror/llvm/blob/ae1ca02d148ec1e591d38a71f429b4804a07f638/include/llvm/ADT/DenseMap.h#L534">这里</a>，注释很清楚，不用解释了;查找bucket的实现在<a href="https://github.com/llvm-mirror/llvm/blob/ae1ca02d148ec1e591d38a71f429b4804a07f638/include/llvm/ADT/DenseMap.h#L573">这里</a>，quadratic probing在<a href="https://github.com/llvm-mirror/llvm/blob/ae1ca02d148ec1e591d38a71f429b4804a07f638/include/llvm/ADT/DenseMap.h#L616<Paste>">这里</a>;空的bucket是EmptyKey，删去一个bucket在原位置放TombStone，找bucket时需要持续探查到第一个EmptyKey，然后返回路上遇到的第一个TomStone或者没有遇到TomStone时返回这个EmptyKey．

