---
title: Lua 5.1 Cheat Sheet
---
## 基础

字符串: 8bit,可以包含\000
string转义中的big mouth

### 语法

### 类型
* nil
* boolean
* number
* string
* function
* userdata
* thread
* table

nil与false均判断为false

number是double

thread是coroutine

table不能用nil索引

table的键值不能是nil

reference语义:

* table
* function
* thread
* (full) userdata

type函数

字符串与数字转换

### 作用域

* global
* local
* table

upvalue/extern local variable

environment table

_env:不是在lua中定义

function's environment table

getfenv

setfenv

### 语句

不允许空语句

技巧: do end添加 break return

list assignment先全部右,后左

As an exception to the free-format syntax of Lua, you cannot put a line break before the '(' in a function call. This restriction avoids some ambiguities in the language.

### 环境

* function
* thread

global environments

* user-data
  只能用c api操纵

## 元表

### GC

weak table: string are values not object

## 协程

lua thread/coroutine是有栈/suspend-down/可以从任意函数调用初yield的.

lua_resume vs lua_call

### 与C API的关系
lua是用纯ansi C写成的,而且还在lua C API中提供了lua_yield这样的接口,但是ansi C是没有stackfull-coroutine的,那lua的C API是如何提供stackfull-coroutine的呢?

答: 手动CPS变换.

## C API