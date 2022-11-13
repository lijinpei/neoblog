# Hazard Pointer与RCU的比较

相同点:

* 解决的问题相同.

在并发数据结构中，假设线程A从共享内存中读了一个指针(假设值是P)到自己的寄存器R中，例如:
R = list_head.load();
等到A开始使用指针时，例如:
next = R->next;
可能发生的事情是:

* P所指向的节点已经从数据结构中移除
* P所指向的节点已经从数据结构中移除，且该节点的数据成员(例如P->next)已经是garbage(指NULL/野指针／undef值等，不是在garbage collection的意义上)
* P所指向的节点已经从数据结构中移除，其P已经被回收(free()/garbage collection),并且被重新利用(例如free()了以后的malloc()又重新返回了P,顺便一提，这样看来malloc()的返回值不是绝对的noalias,只是在free()之前noalias),这时候似乎该节点的值并不是gabarge(在第二条的意义上),但是logically,P已经是一个新的节点了，A此前建立的对P的认识可能已经不再成立，从而可能导致ABA问题.

总而言之，会各种死得很惨.注意到，从共享数据结构中读一个指针或者标记某个节点的引用几乎是不可避免的需求,而没有任何保护措施的情况下,这个很基本的事情都会死得很惨.

一个解决办法是，当A load了一个指针P，A能获得保证P指向的节点

* 可能从逻辑上被删除(否则删除和读取操作不可能是wait-free)
* 可能从"物理上"被删除("逻辑上删除"指,例如在节点上设置一个标记,此时仍能从数据结构中到达这个节点,但是访问这个节点的人能知道这个节点应该已经被视为删除了;"物理上删除"指使无法从数据结构中访问到这个节点,例如修改prev的next指针;两者都不意味着该节点被free()或gc掉)
* 但是节点的数据成员仍然是有意义的成员,访问这些成员不引起undefined behavior
* 节点也不会被free()/gc并重新malloc()开始下一个生命周期

注意到,对于那些"当获得一个对象的指针时,自动增加这个对象的reference counting"的语言,例如Java,这个问题是不存在的,所以TAOMP那本书里没介绍HP和RCU.此外,二者的相同点还包括:

* 线程需要进行注册
* 需要per-thread存储,并且这个per-thread存储需要能被其他线程(deleter/updater)访问
* 某个线程意外死掉不会影响gc

两者的不同点包括:

* 效率.Hazard-Pointer每次load指针,需要写per-thread存储,这意味着访问长度为N的链表的写操作数目是O(N);而RCU一次reader调用只用写一次per-thread存储.写per-thread存储是代价比较高的atomic store(FIXME:这个删除只需保证deleter phisically remove pointer与load其他hp之间的顺序,因而可以是relaxed?).
* 内存回收的粒度:某个被保护的指针是否会影响其他节点的回收.在HP中,一个线程A持有的hp指向的节点不会被回收,并且不会delay其他节点的回收.在naive的粗粒度RCU实现中,一个读线程会阻碍所有的内存回收(TODO:我认为在一些场景下可以用更细粒度的RCU,或者RCU和HP结合的mixed方法).
* 某一节点被删除后仍能存在的时间.假如要保证一个节点被删除,且所有的reader均drop掉对其的reference以后,该节点能保证立马被删除:对于原论文中的Hazard Pointer实现,虽然没有直接讲怎么做(FIXME:这一点需要check一下),原论文中的方案只有等删除进程下一次达到reclaimation的thredshold时才会重新触发对该节点的删除,从而这个时间的长度没有bound,但是我认为很容易修改原算法使得delete且全部reference被drop以后立马删除,且修改过的算法仍然是wait-free的.对于RCU,利用call_rcu()和rcu_read_unlock()应该很容易提供这个保证.

By the way, 我认为下面这篇文章中的方法是RCU的思想.

[使用Hazard Version实现的无锁Stack与Queue](https://zhuanlan.zhihu.com/p/22557362)


