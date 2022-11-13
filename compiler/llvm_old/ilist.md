# Intrusive Double Linked List

Intrusive data structure是一种常见的和C++ STL Container风格不同的容器.用户在使用intrusive data structure时,需要显式地通过继承某些node子类或采用直接包含特定名称的成员等方法,来满足intrusive data structure的contract.相应的好处包括:

* value_type和node的指针所占据的内存同时开辟,减少了new/delete的次数
* 便于实现异质容器(当然,用户自身要能够通过其他方法获取包含node的节点的类型)
* 便于将一个value_type插入多个容器中.

相应的缺点包括:

* 用户要做的事情比STL Container多

其他用到intrusive data structure的地方可参见boost intrusive和linux kernel.(我记得C++ STL中红黑树相关的数据结构的内部实现上也是采用了intrusive的方法,不过需要确认一下)

LLVM的ilist相关的数据结构,实质上是非常简单的intrusive double linked list.相关的文件包括:

* [include/ADT/ilist_base.h](https://github.com/llvm-mirror/llvm/blob/master/include/llvm/ADT/ilist_base.h)
* [include/ADT/ilist.h](https://github.com/llvm-mirror/llvm/blob/master/include/llvm/ADT/ilist.h)
* [include/ADT/ilist_iterator.h](https://github.com/llvm-mirror/llvm/blob/master/include/llvm/ADT/ilist_iterator.h)
* [include/ADT/ilist_node_base.h](https://github.com/llvm-mirror/llvm/blob/master/include/llvm/ADT/ilist_node_base.h)
* [include/ADT/ilist_node.h](https://github.com/llvm-mirror/llvm/blob/master/include/llvm/ADT/ilist_node.h)
* [include/ADT/ilist_node_options.h](https://github.com/llvm-mirror/llvm/blob/master/include/llvm/ADT/ilist_node_options.h)
* [include/ADT/simple_ilist.h](https://github.com/llvm-mirror/llvm/blob/master/include/llvm/ADT/simple_ilist.h)

其中,对用户而言,提供了三种(其实是两种)list:

* [ilist](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist.h#L407)
* [ipist](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist.h#L390)
* [simple_ilist](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/simple_ilist.h#L79)

list_node有一种:
* [list_node](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node.h#L149)

其中ilist是iplist的template alias(所以算是共计两种还是三种随便你).list和list_node的template parameter均相同,T是CRTP了list_node的要插入list的类, Options是一个template parameter pack.对于Options,目前仅支持两种:

* [ilist_sentinel_tracking](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node_options.h#L27)
* [ilist_tag](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node_options.h#L33)

首先,Options中同一个类可以重复指定多次,但是根绝ilist_node_options.h中的实现:

* 只有第一个ilist_tag或者ilist_sentinel_tracking生效
* 未指定ilist_sentinel_tacking为true/false时,视编译时LLVM_ENABLE_ABI_BREAKING_CHECKS宏的值的不同,分别有[默认值](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node_options.h#L69),且设置is_implicit标志.ilsit_tag的默认值是void.

具体如何从parameter pack中提取出这两个标志,是典型的template mateprogramming, 个人感觉和lisp的递归/car/cons操作链表差不多,这里不赘述了,有兴趣请参考ilist_options.h.ilist_options.h中对外界来说,用到的主要是上述两个Options和[ilist_detail::node_options<T, Options...>::type](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node_options.h#L126).

要明白这两个Options的作用,我们需要先深入一下ilist_node的实现,这个类的继承关系如下:

[ilist_node](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node.h#L149) -> [ilist_node_impl](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node.h#L40) -> [ilist_node_base](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node_base.h#L20)

这三个类的区别在于

* ilist_node接受的template parameter是一个T和Options,ilist_node_impl接受的parameter是ilist_node根据T和Options,利用list_node_options.h提供的ilist_detail::node_options<T, Options...>::type.(换句话说,ilist_node的作用是一个在便于用户使用的类和便于实现的类之间的proxy)
* ilist_node_base完全是typeless, 不接受关于value_type的参数,只有指向ilist_node_base的prev/next指针,所有关于类型的信息只出现在ilist_node_impl以上的层.
* 此外ilist_node_impl还是ilist_sentinel的基类,ilist_node还是ilist_node_with_parent的基类.

现在回到ilist_tag和ilist_sentinel_tracking这两个Options上.

ilist_sentinel_tracking的parameter的true/false,最终反映到了ilist_node_base的parameter的true/false上(通过list_node_options.h里的template metaprogramming).当其为true, [ilist_node_base的特化](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node_base.h#L36)的PrevAndSentinel指针抽出了一个bit表示是否是sentinel(通过PointerIntPair).注意到,这意味着,你必须给list的他的node传入相同的ilist_sentinel_tracking参数.当enable了这个选项时,ilist_node_base有一个[isSentinel()](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node_base.h#L46)方法,无论是都enable,均有[isKnownSentinel()](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node_base.h#L32)方法,isKnownSentinel()方法当enable时与isSentinel()相同,不enable时恒定返回false(error on the safe side)

对于ilist_tag,考虑这样一个问题,假如你有一个T类型,你希望T可以*同时*被加入list_A和list_B,那么现在你需要T里有两套prev/next指针,但是问题是,你无法继承同一个ilist_node<T>类两次.解决的办法是,继承ilist_node<T, TagA>和list_node<T, TagB>,TagA和TagB是随便两个不同的类,他们只是用来区分list_node,甚至可以是空类.现在ilist_node<T, Tag>, ilist_node<T, TagB>是两个不同的,没有继承关系的类了,从而你获得了两套prev/next指针(更具体地,ilist_node<T, TagA>和ilist_node<T, TagB>是两个不同的,没有继承关系的类,因为前面我们说了,ilist_node -> ilist_node_impl,而ilist_node_impl的参数是一个ilist_detail::node_options<T, Options...>::type也即[node_options](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node_options.h#L108), 我们可以看到node_options是templated on tag的).此外,要求ilist也要传入相应的Tag做Options,不过我觉得没有必要这样设计.如果上面的解释不清楚的话,你可以看看这里的[注释](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_node.h#L129).

上面分析完了ilist_node,下面开始分析ilist.以下分析中,经常会遇到一个叫OptionsT的template parameter,实际上就是list_node_options.h中的ilist_detail::node_options,他包含了T(T crtp了list_node), tag和sentinel_tracking.

首先是list_node.h中的[ilist_detail::NodeAccess](https://github.com/llvm-mirror/llvm/blob/87a4c58e539315eff07ddb593c38894704858a2c/include/llvm/ADT/ilist_node.h#L164)和[ilist_detail::SpecificNodeAccess](https://github.com/llvm-mirror/llvm/blob/87a4c58e539315eff07ddb593c38894704858a2c/include/llvm/ADT/ilist_node.h#L211).这两个类都是template(参数是OptionsT),只有static方法(类似traits的感觉),提供了和T和list_node<T>相关的一些操作.这两个类的不同在于,NodeAccess的template parameter是各个方法上的,SpecificNodeAccess的template parameter在整个类上面(其实只是为了使用的方便提供了两种,实质上没太大区别).这两个类提供的功能是

* 提供访问ilist_node_impl的next/prev指针.ilist_node_base是ilist_node_impl的私有基类,但是ilist_node_impl friend了NodeAccess/ilist_sentinel/ilist_iterator.(SpecificNodeAccess forward到NodeAccess). ilist操作ilist_node均通过这两个NodeAccess类.
* 提供T和ilist_node_impl之间的转换.注意到T可能含有多个ilist_node_impl基类(通过不同的Tag),而模板参数OptionsT决定了同哪个基类之间互相转换.

前面提到过有三(两)种ilist,它们的区别是

* simple_ilist不拥有插入节点的所有权,不new/delete节点.
* iplist拥有插入节点的所有权,自行new/delete节点,提供了一些callback会在delete和其他时候调用.

相应的继承关系是:

* ilist是iplist的tamplate alias
* iplist继承[iplist_impl](https://github.com/llvm-mirror/llvm/blob/87a4c58e539315eff07ddb593c38894704858a2c/include/llvm/ADT/ilist.h#L168). iplist_impl有两个模板参数,IntrusiveListT是一个不take-ownership的intrusive list(ilpist关于这个参数传入的是simple_ilist),TraitsT就是决定了callback的类traits(iplist传入的是ilist_traits<T>)
* iplist_impl继承了IntrusiveListT.IntrusiveListT应当不take-ownership,splist_impl负责节点的new/delete然后交给IntrusiveListT操作,并调用TraintsT的callback.
* simple_ilist继承OptionsT::list_base_type, 也就是[ilist_base](https://github.com/llvm-mirror/llvm/blob/96dd58bd6cd91b5815c15e3b3d54dec9898c5db6/include/llvm/ADT/ilist_base.h#L19),并拥有[Sentinel成员](https://github.com/llvm-mirror/llvm/blob/87a4c58e539315eff07ddb593c38894704858a2c/include/llvm/ADT/simple_ilist.h#L88)
* ilist_base的模板参数只是<bool EnableTracking>,这意味着它只对ilist_node_base进行操作,此外,ilist_base中没有sentinel.

此外,关于traits要提供哪些方法,参见[ilist_alloc_traits](https://github.com/llvm-mirror/llvm/blob/87a4c58e539315eff07ddb593c38894704858a2c/include/llvm/ADT/ilist.h#L41)和i[list_callback_traits](https://github.com/llvm-mirror/llvm/blob/87a4c58e539315eff07ddb593c38894704858a2c/include/llvm/ADT/ilist.h#L65).注意到alloc_traits中没有关于new的方法,iplist_impl中,传入指针和reference的insert()方法不需要new,传入const reference的insert()方法调用的是[operator new()](https://github.com/llvm-mirror/llvm/blob/87a4c58e539315eff07ddb593c38894704858a2c/include/llvm/ADT/ilist.h#L234).

此外,ilist.h中还用到了member detecter,来检查traits是否使用的是旧的api,例如[HasGetNext](https://github.com/llvm-mirror/llvm/blob/87a4c58e539315eff07ddb593c38894704858a2c/include/llvm/ADT/ilist.h#L102).

ilist_iterator存储的状态是一个[node_pointer](https://github.com/llvm-mirror/llvm/blob/87a4c58e539315eff07ddb593c38894704858a2c/include/llvm/ADT/ilist_iterator.h#L79), 也即指向[ilist_node_impl的指针](https://github.com/llvm-mirror/llvm/blob/87a4c58e539315eff07ddb593c38894704858a2c/include/llvm/ADT/ilist_iterator.h#L29).sentinel初始为[指向自己的环形](https://github.com/llvm-mirror/llvm/blob/dde13123001de582f94065c0c49545740cfcc649/include/llvm/ADT/ilist_node.h#L244)

对llvm intrusive double linked list的乏味而又冗长的讨论到此结束.
