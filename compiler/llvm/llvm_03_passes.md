title: LLVM学习笔记: Passes
---
这篇博客主要介绍llvm里主要的Pass，它们做了什么，如何工作。另外一篇关于Pass Manager博客会介绍llvm的Pass是如何组织的，我们会把诸如Pass间依赖，执行顺序，数据传递之类的问题留到关于Pass Manager的那篇博客中讨论.

### Transform与Analysis

Pass可以划分为两种:

- Transform: 可能改变IR
- Analysis: 不改变IR，只从IR中获取信息