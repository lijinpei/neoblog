# Shared-memory Multi-processor Programming

[Hazard Pointer与RCU的比较](hp_vs_rcu.html)

## 各种Memory Model(Memory Order的意义上)
### 软件

* C++ Memory Model
  * [Memory Model](http://en.cppreference.com/w/cpp/language/memory_model)
  * [std::memory_order](https://en.cppreference.com/w/cpp/atomic/memory_order)
  * [std::atomic](http://en.cppreference.com/w/cpp/atomic/atomic)
* Linux "Memory Model"
  * [memory barriers](https://github.com/torvalds/linux/blob/master/Documentation/memory-barriers.txt)
  * [atomic_t](https://github.com/torvalds/linux/blob/master/Documentation/atomic_t.txt)
  * [Linux Kernel Memory Model, p0124r5](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p0124r5.html)
* LLVM Memory Model
  * [LLVM Atomic Instructions and Concurrency Guide](https://llvm.org/docs/Atomics.html)

### 硬件
* [X86 TSO](https://www.cl.cam.ac.uk/~pes20/weakmemory/cacm.pdf)
* [ARM/POWER Relaxed Memory Model](https://www.cl.cam.ac.uk/~pes20/ppc-supplemental/test7.pdf)

[Solutions and Codes to TAOMP](TAOMP.html)

[Software Tools](software.html)

[Processor Architecture](procesor.html)

[Papers](papers.html)

Useful Links

* rcu
  * [linux kernel document](https://github.com/torvalds/linux/tree/master/Documentation/RCU)
  * liburcu [website](http://liburcu.org/) [code](https://github.com/urcu/userspace-rcu)
* [libcds] (https://github.com/khizmax/libcds)
* intel tbb [website](https://github.com/01org/tbb) [code](https://www.threadingbuildingblocks.org/)
