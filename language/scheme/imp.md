---
title: ChezScheme Macro Expander源码分析
date: 2019-05-09
tags:
  - Scheme
  - ChezScheme
  - Hygienic Macro
---
## 介绍

## 前置知识

### Datum

### Phase

### NanoPass Framework

#### NP in ChezScheme

### Compile Time Value

## 核心算法

### 算法原理

### 算法实现

#### Parse输出: chi-*系列函数

#### 组装输出: build-*系列函数

## 一些有趣的点

### 出现在Binding位置的Syntax-Object

### `free-identifier=?`与`bound-identifier=?`

### Core Form

### Core Form与Macro的区别

### 再看Phase

### 非自举
(current-expnad sc-expand)