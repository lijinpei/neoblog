# LLVM ADT

ADT的头文件在include/llvm/ADT目录下，部分需要.cpp文件的，相应的.cpp文件在lib/Support目录下，例如lib/Support/APInt.cpp. Support目录下是一些为了隔离开操作系统依赖，便于移植的功能性library，你可以浏览一下这两个目录的内容，感受一下它们的不同．ADT都位于namespace llvm下，部分Support库的内容位于llvm::support下，其他也直接在namespace llvm下. 对于header-only的ADT库，直接引用头文件就可以使用，例如include/llvm/ADT/EquivalenceClasses.h就是一个header-only的头文件，不是header-only的需要动态/静态链接到相应的libLLVM.so/libLLVM.a等目标库文件. 似乎ADT和Support都只依赖于C++标准库，config和对方(除了部分Support的实现依赖platform specific header, 例如lib/Support/Unix, lib/Support/Windows, 以及include/llvm/Support/Solaris/sys/regset.h这个workaround).

这篇文章计划详细介绍ADT中所有组件的实现细节.这是一项正在进行中的工作,我计划每周完成下面列表中的一个方面的介绍.

["小"和"稀疏"](small_sparse.html)

["vector"和"array"](vec_arr.html)

["字符串"](string.html)

[初级数据结构](simple.html)

[侵入式双链表](ilist.html)

[哈希表](hashtable.html)

[中级数据结构](medium.html)

* AVL-tree
* EquivalenceClasses并查集.
* FoldingSet另一种哈希表.

[图](graph.html)

* GraphTraits
* BreadthFirstIterator
* DepthFirstIterator
* PostOrderIterator
* SCCIterator

[任意精度整数/浮点数](AP.html)

[标准库扩展](extension.html)

* None
* Optional
* iterator
* iterator_range
* STLExtras

[小工具](utilsi.html)

* StringRef/Twine
* IntrusiveRefCntPtr
* PointerIntPair
