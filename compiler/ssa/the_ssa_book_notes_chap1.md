##
SSA: Static Single Assignment

A program is defined to be in SSA form if each variable is a target of exactly one assignmentstatement in the program text.

referencial transparency:
since there is only a singledefinition for each variable in the program text, a variable’s value isindependentof its positionin the program

Pro-grams written in pure functional languages are referentially transparent. 

Suchreferentially transparent programs are more amenable to formal methods andmathematical reasoning, since the meaning of an expression depends only onthe meaning of its subexpressions and not on the order of evaluation or sideeffects of other expressions.

phi-function
pseudo-assignment function/notational function

It is important to note that, if there are multipleφ-functions?at the headof a basic block, then these are executed in parallel,
Whenφ-functions are elimiated in the SSA destructionphase, they are sequentialized using conventional copy operations, 
φif?orγ?functions

(dynamic) sin-gle assignment (DSA or simply SA) form used in automatic parallelization

Staticsingle assignment does not prevent multiple assignments to a variable duringprogram execution.Staticsingle assignment does not prevent multiple assignments to a variable duringprogram execution.

dense: per-variable, per-program-point
sparse: per-variable
operational/functional(sparse)

For other data-flow problems, properties may change at points that are notvariable definitions. These problems can be accommodated in a sparse analysisframework by inserting additional pseudo-definition functions at appropriatepoints to induce additional variable renaming. 

sparsedef-use chains

dependence graph style IRs

immutability simplifies concurrentprogramming

dualities betweenSSA and functional programming.

control-flow insensitive analyses

single reaching-definition property

minimality property

join node

strict

dominance property:

minimal SSA form

live-range

interfere

chordal graphs
graph coloring
tree scan algorithm

Making a non-strict SSA code strict is about the same complexity as
SSA construction

pruned ssa