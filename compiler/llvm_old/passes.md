# Analysis and Transformation Passes

# Tier 0 the Bases of the Bases

## TLI(Taget Library Info)
## DL(Data Layout)

# Tier 1 Basic Analysis that does't dependent on other analysis(except Tier 0)

## Alias Analysis

### BasicAA
### TBAA
### CFL-AA
#### CFL-Andersen AA
#### CFL-Steensgaard AA
### Memory-SSA

## Dominator Tree

### DomTree
### DominanceFrontier
### IteratedDominanceFrontier
### LoopInfo
### RegionInfo

# Tier 2 Key Analysis that dependent on other analysis

## SSA
### Mem2Reg

## GVN

## SCEV(Scalar Evolution)

## Scop(Static Control Block)
