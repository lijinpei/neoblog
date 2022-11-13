# CFL-AA

TODO:

Context-Free-Language(CFL)用来以flow-insensitive的方式描述所有与Alias Analysis有关的信息,构造出Program Expression Graph.

Andersens和Steensgaard两种在PEG之上计算Alias的算法(尽管这两种算法提出时没有针对CFL).基本的方法分别是搜索和并查集,复杂度分别为O(n^3)和O(alpha(n) * n).

附自己实现的[steensgaard](https://github.com/lijinpei/llvm/blob/d75e73cf43f42658176fef029cca0450cd7488cf/lib/Analysis/StratifiedSets.h)(FIXME:修正attribute propagate中的bug)
