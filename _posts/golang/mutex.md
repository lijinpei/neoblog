title: golang sync.mutex实现分析
date: 2019-04-04
tags:
  - golang
  - concurrency
---
本来去看[golang的mutex源码的实现](https://github.com/golang/go/blob/17436af8413071a50515c90af69c23f77cb201e3/src/sync/mutex.go)，是为了验证一下golang的mutex是锁住goroutine而不锁住thread的，然后看了一下源码，发现这个事情取决于`runtime_SemacquireMutex()`和`runtime_Semrelease()`这两个函数是锁住goroutine还是锁住thread，等以后有空再写个golang semaphore的源码分析吧。然后在我花了一个下午和一个晚上看了看这个mutex的源码之后(没错，225行代码我看了一个下午和晚上)，我发现golang的这个mutex有点意思.

## 数据表示
golang的mutex在数据表示上需要8个byte.
```
// A Mutex is a mutual exclusion lock.
// The zero value for a Mutex is an unlocked mutex.
//
// A Mutex must not be copied after first use.
type Mutex struct {
	state int32
	sema  uint32
}
```
其中,state表示锁的状态,sema是一个semaphore,等待这个semaphore的进程构成一个队列queue.可以想象，基本的工作原理是:
```
mutex_v1:
lock:如果能cas成功锁的状态，那么解锁成功，否则睡到queue上.
unlock:原子地改变锁的状态，并从queue中唤醒最多一个进程.
```
不过golang的mutex要比这个复杂一些.

## 两种操作模式
Golang的mutex有两种操作模式:
- Normal Mode
- Starvation Mode
初始化mutex处于normal mode的unlocked状态。Normal mode和上面描述的mutex_v1工作原理基本相同，不过采取了一个优化:
```
mutex_v2:
在mutex_v1的基础上，如果unlock时有新的goroutine正在试图lock，那么不从queue中唤醒goroutine.(隐含的意味是，某个新来的goroutine会获得锁)
```
这个优化的动机是，新来的goroutine是缓存(比如instruction cache, data cache, TLB等)热的goroutine，已经在queue上睡过的goroutine是缓存冷的goroutine，优先调度热缓存goroutine有利于系统整体的资源利用效率.

但是这个策略有个问题，已经睡到queue上的goroutine可能会因为不断地有新的goroutine抢去锁而被饿死(实际表现为解锁延迟特别长)，为了弥补这个问题(后面我们会看到这个问题并没被解决),golang的mutex另有一种FIFo的公平模式，也就是starvation mode,在此模式下锁的工作情况如下:
```
mutex_v3, starvation mode:
lock: cas锁状态，如果成功则上锁成功，如果失败则以FIFO的顺序睡到queue上
unlock: 从FIFO上唤醒至多一个goroutine.
```
这个基本上就是mutex_v1，不同之处在于以下两点:
1. 唤醒goroutine的顺序,mutex_v1为FILO(栈)，mutex_v3为FIFO(队列).这分别是优先调度热goroutine从而保证系统利用效率/优先调度等待时间长(冷)的goroutine从而保证公平避免waiting-time中的长尾.
2. mutex_v1可以单独作为完整正确的锁，mutex_v3只有在queue非空的前提下才是正确的锁，因为mutex_v3在解锁时没有清除锁状态那一步.Golang的mutex在成功解锁且发现queue为空以后，会试图把锁从starvation mode切换到normal mode，所以在这个问题上没有正确性问题.
不过我们将会看到事实上golang的mutex并没有提供这种保证.

## 真的能避免starvation吗?

我们知道以FIFO方式操作队列的mutex(也就是mutex_v1改为FIFO仿时操作或者mutex_v3解锁时加上原子地更改锁状态)是可以避免starvation的,至少在理论的意义上:
```
假设进程P入队后队列的长度为L，那么L次成功的解锁以内P会获得锁.
```
那么golang的mutex能提供防starvation保证吗?
```
假设进程P入队时队列的长度为L，那么是否存在时间T和函数f(L),使得过去L时间且经历过f(L)次成功解锁以后,P会成功获得锁?
```
我认为答案是否定的，而且否定的原因比较trival:
```
golang的mutex能保证进程P在f(L)次成功解锁以内获取到锁取决于锁被切换到了starvation mode，这又依赖于某次成功解锁是由queue中唤醒的元素执行的，但是完全可能每次解锁正好有新来的goroutine by-pass掉队列中的goroutine，从而永远无法切换到starvation mode，从而无法保证f(L)次成功解锁以内P获得锁.(或者即使queue中的goroutine获得了锁，这个goroutine自己没有超时,但是这些等待时间会积累，从而队列中其他goroutine可能已经等待了任意长时间)
```

## code-walk
下面是针对[commit 17436af841](https://raw.githubusercontent.com/golang/go/17436af8413071a50515c90af69c23f77cb201e3/src/sync/mutex.go)版本的golang mutex的我添加了注释的代码.
```golang
// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package sync provides basic synchronization primitives such as mutual
// exclusion locks. Other than the Once and WaitGroup types, most are intended
// for use by low-level library routines. Higher-level synchronization is
// better done via channels and communication.
//
// Values containing the types defined in this package should not be copied.
package sync

import (
	"internal/race"
	"sync/atomic"
	"unsafe"
)

func throw(string) // provided by runtime

// A Mutex is a mutual exclusion lock.
// The zero value for a Mutex is an unlocked mutex.
//
// A Mutex must not be copied after first use.
type Mutex struct {
	state int32
	sema  uint32
}

// A Locker represents an object that can be locked and unlocked.
type Locker interface {
	Lock()
	Unlock()
}

const (
// let nWaiter = mutex.state >> mutexWaiterShift;
// nWaiter表示睡在queue上的goroutine个数.
// 有些不变量这里没有记载:
// 在Normal Mode下,mutexWoken置位表示有一个（新来的）goroutine窃取了从队列中唤醒goroutine的责任/by-pass掉持有锁的goroutine唤醒队列中goroutine的操作
// 在Starvation Mode下,mutexWoken不起作用，且应置为0

	mutexLocked = 1 << iota // mutex is locked
	mutexWoken
	mutexStarving
	mutexWaiterShift = iota

	// Mutex fairness.
	//
	// Mutex can be in 2 modes of operations: normal and starvation.
	// In normal mode waiters are queued in FIFO order, but a woken up waiter
	// does not own the mutex and competes with new arriving goroutines over
	// the ownership. New arriving goroutines have an advantage -- they are
	// already running on CPU and there can be lots of them, so a woken up
	// waiter has good chances of losing. In such case it is queued at front
	// of the wait queue. If a waiter fails to acquire the mutex for more than 1ms,
	// it switches mutex to the starvation mode.
	//
	// In starvation mode ownership of the mutex is directly handed off from
	// the unlocking goroutine to the waiter at the front of the queue.
	// New arriving goroutines don't try to acquire the mutex even if it appears
	// to be unlocked, and don't try to spin. Instead they queue themselves at
	// the tail of the wait queue.
	//
	// If a waiter receives ownership of the mutex and sees that either
	// (1) it is the last waiter in the queue, or (2) it waited for less than 1 ms,
	// it switches mutex back to normal operation mode.
	//
	// Normal mode has considerably better performance as a goroutine can acquire
	// a mutex several times in a row even if there are blocked waiters.
	// Starvation mode is important to prevent pathological cases of tail latency.
	starvationThresholdNs = 1e6
)


// Lock locks m.
// If the lock is already in use, the calling goroutine
// blocks until the mutex is available.
func (m *Mutex) Lock() {
	// Fast path: grab unlocked mutex.
	if atomic.CompareAndSwapInt32(&m.state, 0, mutexLocked) {
		if race.Enabled {
			race.Acquire(unsafe.Pointer(m))
		}
		return
	}
	// Slow path (outlined so that the fast path can be inlined)
	m.lockSlow()
}

func (m *Mutex) lockSlow() {
	var waitStartTime int64
	starving := false
	awoke := false
	iter := 0
	old := m.state
	for {
		// Don't spin in starvation mode, ownership is handed off to waiters
		// so we won't be able to acquire the mutex anyway.
		if old&(mutexLocked|mutexStarving) == mutexLocked && runtime_canSpin(iter) {
      //如果是Normal Mode下
			// Active spinning makes sense.
			// Try to set mutexWoken flag to inform Unlock
			// to not wake other blocked goroutines.
      // 这里 !awoke应该是一个不必要的检查?
      if !awoke && old&mutexWoken == 0 && old>>mutexWaiterShift != 0 &&
      // cas验证Normal Mode仍成立，这里不会有ABA问题.
				atomic.CompareAndSwapInt32(&m.state, old, old|mutexWoken) {
				awoke = true
			}
			runtime_doSpin()
			iter++
			old = m.state
			continue
		}
		new := old
		// Don't try to acquire starving mutex, new arriving goroutines must queue.
		if old&mutexStarving == 0 {
			new |= mutexLocked
		}
		if old&(mutexLocked|mutexStarving) != 0 {
			new += 1 << mutexWaiterShift
		}
		// The current goroutine switches mutex to starvation mode.
		// But if the mutex is currently unlocked, don't do the switch.
		// Unlock expects that starving mutex has waiters, which will not
		// be true in this case.
		if starving && old&mutexLocked != 0 {
			new |= mutexStarving
		}
		if awoke {
			// The goroutine has been woken from sleep,
			// so we need to reset the flag in either case.
			if new&mutexWoken == 0 {
				throw("sync: inconsistent mutex state")
			}
			new &^= mutexWoken
		}
		if atomic.CompareAndSwapInt32(&m.state, old, new) {
			if old&(mutexLocked|mutexStarving) == 0 {
				break // locked the mutex with CAS
			}
			// If we were already waiting before, queue at the front of the queue.
			queueLifo := waitStartTime != 0
			if waitStartTime == 0 {
				waitStartTime = runtime_nanotime()
			}
			runtime_SemacquireMutex(&m.sema, queueLifo, 1)
			starving = starving || runtime_nanotime()-waitStartTime > starvationThresholdNs
			old = m.state
			if old&mutexStarving != 0 {
				// If this goroutine was woken and mutex is in starvation mode,
				// ownership was handed off to us but mutex is in somewhat
				// inconsistent state: mutexLocked is not set and we are still
				// accounted as waiter. Fix that.
				if old&(mutexLocked|mutexWoken) != 0 || old>>mutexWaiterShift == 0 {
					throw("sync: inconsistent mutex state")
				}
				delta := int32(mutexLocked - 1<<mutexWaiterShift)
				if !starving || old>>mutexWaiterShift == 1 {
					// Exit starvation mode.
					// Critical to do it here and consider wait time.
					// Starvation mode is so inefficient, that two goroutines
					// can go lock-step infinitely once they switch mutex
					// to starvation mode.
					delta -= mutexStarving
				}
				atomic.AddInt32(&m.state, delta)
				break
			}
			awoke = true
			iter = 0
		} else {
			old = m.state
		}
	}

	if race.Enabled {
		race.Acquire(unsafe.Pointer(m))
	}
}

// Unlock unlocks m.
// It is a run-time error if m is not locked on entry to Unlock.
//
// A locked Mutex is not associated with a particular goroutine.
// It is allowed for one goroutine to lock a Mutex and then
// arrange for another goroutine to unlock it.
func (m *Mutex) Unlock() {
	if race.Enabled {
		_ = m.state
		race.Release(unsafe.Pointer(m))
	}

	// Fast path: drop lock bit.
	new := atomic.AddInt32(&m.state, -mutexLocked)
	if new != 0 {
		// Outlined slow path to allow inlining the fast path.
		// To hide unlockSlow during tracing we skip one extra frame when tracing GoUnblock.
		m.unlockSlow(new)
	}
}

func (m *Mutex) unlockSlow(new int32) {
	if (new+mutexLocked)&mutexLocked == 0 {
		throw("sync: unlock of unlocked mutex")
	}
	if new&mutexStarving == 0 {
		old := new
		for {
			// If there are no waiters or a goroutine has already
			// been woken or grabbed the lock, no need to wake anyone.
			// In starvation mode ownership is directly handed off from unlocking
			// goroutine to the next waiter. We are not part of this chain,
			// since we did not observe mutexStarving when we unlocked the mutex above.
			// So get off the way.
			if old>>mutexWaiterShift == 0 || old&(mutexLocked|mutexWoken|mutexStarving) != 0 {
				return
			}
			// Grab the right to wake someone.
			new = (old - 1<<mutexWaiterShift) | mutexWoken
			if atomic.CompareAndSwapInt32(&m.state, old, new) {
				runtime_Semrelease(&m.sema, false, 1)
				return
			}
			old = m.state
		}
	} else {
		// Starving mode: handoff mutex ownership to the next waiter.
		// Note: mutexLocked is not set, the waiter will set it after wakeup.
		// But mutex is still considered locked if mutexStarving is set,
		// so new coming goroutines won't acquire it.
		runtime_Semrelease(&m.sema, true, 1)
	}
}
```