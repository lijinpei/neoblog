# Dominator-Tree

TODO:

* 算法0: Data-flow equation

首先,显然dominator构成的集合满足data-flow equation的条件.其次需要证明迭代法求的一定是dominator构成的集合,分两条来证:

1. 若u不dominate v,则u一定不在v_out中.
显然u不是r.
当v是根r时显然.
当v不是根r时,因为u不dominate v,故存在一条从r到v的不含u的(简单)路径.考虑这条路径,因为只有u会在输入集合不含u时在输出集合中引入u,而这条路径不含u,但是路径的终点v的输出v_out含u,根绝归纳法可以得出路径上任一节点的输入与输出均含u,而u不是r,r的输出不含u,矛盾.

2. 若u是v的dominator,则u一定在v_out中:
考虑u dominate的region,u一定在u_out中.假设对于这个region中的点,迭代法求出的解是X,令X中的每个集合均并上{u}构成的解是X2,则显然,对于X2,region中的点的数据流方程均满足,对于region外的点,如果其输入不含region中的点,则其输入输出不变,若其输入含有region中与region外的点(其输入不可能全部为region中的点,否则这个点也在region中),则由于region外的点的输出不含u,故在部分输入中并入u,数据流方程仍满足.这样我们得到了一个不小于X1的解X2.而迭代法求出的是最大的解,故X1=X2,从而u在v_out中.

* 算法1: Lengauer Tarjan Algorithm

引理:对于图G(V, E), G的一个DFST T,T上计算出的sdom关系,则图G1 = (V, {x 属于V |(sdom(x), x)} 并上T中树边)与图G具有相同的dominator关系.
证明:
由于dom(u)只可能是u在T上的祖先节点,故只考虑u在T上的一个祖先节点p.需要证明两个事情:


1. 若p在G中dominate u,则p在G1中dominate u.
反之,p在G1中不dominate u,那么G1中存在一条从r到u的简单路径P不经过p.注意到G1中没有可以从一棵子树中出去的retreating edge或cross edge,从而P中只可能有r到u的DFST路径上的边,或(sdom(x), x)型的边,其中x一定是u的祖先.将(sdom(x), x)替换为G中一条相应的路径后(总可以使得这条路径除端点以外不含u的祖先),这样得到了一条G中从r到u的不含p的路径,与p在G中dominate u矛盾.

2. 若p在G中不dominate u,则p在G1中不dominate u.
由p在G中不dominate u, 存在一条从r到u的不含p的简单路径P.设P上最后一个是u的祖先,且dfs order大于p的节点为p1(也就是说p1在DFST中(p, u]的范围内),因为u是一个满足这个条件的节点,从而必然存在p1.设p2是路径P上,在p1之前,且是p1的祖先的节点的最后一个,由于r是满足这样要求的节点,从而p2一定存在.那么sdom(p1) <= p2(也就是说sdom(p1)从dfst上看是p2或其祖先).
考虑(简单)路径P上从p2到p1这段,则这段路径上出端点p2和p1外另一个点w(如果存在)的dfs order必然大于p1,反之w <= p1,由引理"从dfs order小的节点x到dfs order大的节点y的路径上必然含有x和y的公共祖先"可知这段路径上含有p1的祖先,而p2是P上p1之前的第一个p1的祖先,矛盾.从而sdom(p1) <= p2.考虑G1中沿dfst树边r->sdom(p1)->p1->u的路径,则这条路径不含p,从而p在G1中不dominate u.

* 算法2: Semi-NCA
