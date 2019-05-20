title: CMake Language学习笔记
date: 2019-05-01
---
## 文件组织
CMake语言源代码文件组织为3种:

* 目录
* 脚本
* 模块

## 变量作用域
CMake中变量总是string类型，当然有些命令会把字符串的内容解释为数值,list等.

变量名大小写敏感.

变量有动态作用域.作用域有三种:

* 函数作用域
* 目录作用域
* 持续缓存

使用set()/unset()来创建/删除变量.

所谓动态作用域:
```cmake
function (f1)
  message (INFO ${var_bar})
endfunction()

function (bar1)
  set (var_bar "bar1")
  f1()
endfunction()

function (bar2)
  set (var_bar "bar2")
  f1()
endfunction()

bar1()
bar2()
```
用`cmake -P`运行这段代码的输出是:
```
INFObar1
INFObar2
```

关于目录作用域,似乎运行时只会有一个活跃的目录作用域,也就是说，如果没有在当前目录作用域找到某个变量，是不会往上级目录找的.也就是说，有效的活跃作用域是一个cache作用域，一个目录作用域，多个嵌套的函数作用域.

proj/CMakeLists.txt:
```cmake
set(var1 proj)
add_subdirectory(subproj)
fun_disp()
```
```cmake
proj/subproj/CMakeLists.txt
function (fun_disp)
  message (INFO ${var1})
  unset(var1)
endfunction ()

function (fun_1)
  set(var1 fun_1)
  fun_disp()
endfunction ()

message(INFO "inside subproj " ${var1})
set(var1 subproj)
message(INFO "subproj set var " ${var1})
fun_1()
unset(var1)
fun_disp()

```
运行结果:
```
INFOinside subproj proj
INFOsubproj set var subproj
INFOfun_1
INFO
INFOproj
```
注意，进入子目录时，会复制一份父目录的变量(这只是行为性质的描述，不代表实现是这样).
注意，当set()/unset()有PARENT_SCOPE参数的时候，行为有所不同,这时候子目录作用域可以操纵父目录作用域的绑定.
另外，函数本身会引入函数作用域(这是函数与宏的区别)，但是函数名本身没有处于嵌套作用域结构中.

cache变量只能通过在set()/unset()时加入CACHE来操纵,要注意:

1. 当cache变量已存在时,set()无效,除非FORCE.
2. 成功set() cache变量后会清除当前作用域中的同名变量(不会影响父作用域或其他作用域中的变量).

```cmake
function(set_cache)
set(var set_cache)
set (var cache CACHE STRING test_cache FORCE)
message (INFO " set_cache: " ${var})
endfunction()

function(func1)
set (var "func1")
set_cache ()
message (INFO " func1(): " ${var})
endfunction()

set (var directory)
func1()
message (INFO " directory(): " ${var})
```
## 变量引用
变量引用的语法是
```
${变量名}
```
这种用法是可以嵌套的
```
${外层${内层变量名}变量名}
```
这种引用方法会查找普通变量和cache变量，如果想只查找cache变量:
```
$CACHE{cache变量名}
```
如果想引用环境变量:
```
$ENV{环境变量名}
```
变量引用可以用于命令参数,注意if()命令有automatic-evaluation.

## 命令参数

有三种命令参数:
* bracket argument
* quoted argument
* unquoted argument

bracket argument和quoted argument传入命令中是一个参数,unquoted argument会经过和list一样的分割然后作为0个或多个参数传入命令.

