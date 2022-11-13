byte: 至少8bit
memory location: 两个线程可以同时访问两个memory location

object mode:
object的制造:
  定义
  new表达式
  隐式改变union的活跃成员
  临时对象的制造

object占用空间:
period of construction
lifetime
period of destruction

函数不是对象(虽然函数也占用空间)

storage duration(影响lifetime)
type

polymorphic object
non-polymorphic object

subobjects:
  member
  base
  array-subobjects
complete object

reference/const sub-subobject
std::launder

array of unsigned char/std::byte可以用于provide storage for
nested within: subobject和provide-storage-for的传递闭包
complete-object: 按照sub-object关系找到根
most-derived-object: 排除base-sub-object

trivially-copyable/standard-layout

两个object拥有同样的地址:
  1 lifetime不overlap
  2 假设lifetime overlap
    2.1 provide-storage-for
    2.2 base-subject of non-zero size

observable behavior:
"as-if" rule

full-expression

side-effect:读volatile glvalue也属于side-effect

sequenced-before
unsequenced
indeterminately sequenced
The execution of unsequenced evaluations can overlap.

hosted implementation
freestanding implementation

conflict
synchronization operation:
consume
acquire
release
both acquire and release

synchronize with
release sequence
modification order of atomic object M
carries a dependency into
dependency-ordered before
inter-thread happens before
happens before
strongly happens before

potentially concurrent: 包括concurrent和singnal handler的情况

volatile std::sig_atomic_t
