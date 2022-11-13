# LLVM Study Notes

Here are some study notes I made during my still on-going learning of LLVM/compilation techniques. I wrote them here to clear my mind/serve as a memo for myself, and maybe provide an ovrerview for new-comers to llvm.

[Algorithms](algorithms.html). My repeat of certain algorithms used in LLVM.

[Basics](basics.html). Explain how basic things are represented in LLVM.

[LLVM ADT](ADT.html). ADT means abstract datastructure type, they are like cpp standard library's STL but provides additionaly functionality suitable for llvm/clang's needs. ADT is a base layer for other functionality of llvm/clang, they are less concerned with algorithms used in a compiler, but exhibit good C++ engineering practice.

[LLVM Analysis and Transformation passes](passes.html). Analyses and transformations are where llvm's most optimization happens(well, at least most target-independent optimization happens).

[LLVM Machine Code Generation](mc.html). Machine code generation is the process by with LLVM IR get tranformed into object code that can be 'executed' by a CPU.

[LLVM JIT](jit.html).

[Polly](polly.html). [LLVM's polly subproject](http://polly.llvm.org) is an implementation of the <a href="http://polyhedral.info/"> polyhedral compilation </a> technique, which at optimize <a href="https://polly.llvm.org/doxygen/classpolly_1_1Scop.html"> 'scop'</a> (static control part) loops for data locality (i.e. cache friendly) and vectorization (possibily?).</p>
