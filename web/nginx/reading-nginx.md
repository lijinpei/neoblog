date: 2019-03-11
title: Nginx阅读笔记
---
## 关于Nginx架构

- [架构](https://www.nginx.com/blog/inside-nginx-how-we-designed-for-performance-scale/)
- [架构](https://www.aosabook.org/en/nginx.html)

关键词: event-driven, 多进程, state-machine, Nginx更新, 配置更新

其实关键点不在于多进程还是多线程，而是一个进程/线程是只能服务一个connection还是可以服务多个connection.

-[Socket Sharding](https://www.nginx.com/blog/socket-sharding-nginx-release-1-9-1/)

关键词: Socket Sharding, SO_REUSEPORT

基本上就是SO_REUSEPORT的应用,在连接需要的处理比较简单/快速的场景下可以略微降低latency, 大大降低lantency的标准差.这个有点出乎我的意料,以后有时间的话看看为什么SO_REUSEPORT比一个listen socket + 后面一个进程池在这种场景下latency方面性能好.

- [Tuning-Nginx](https://www.nginx.com/blog/tuning-nginx/)
- [HTTP Keepalive](https://www.nginx.com/blog/http-keepalives-and-web-performance/)

关键词: Backlog Queue, HTTP Keepalive, Nginx限速

HTTP Keepalive可能对服务器带来不利的影响，可能占用完服务器的并发连接数.Nginx的应对办法是由Nginx做proxy来面对大量的keepalive连接,自己维护一个连接池到上游.我没有仔细看[apache的应对](https://httpd.apache.org/docs/2.4/mod/event.html).

- [wg/wrk](https://github.com/wg/wrk)

一个HTTP Benchmark工具.

- [shekyan/slowhttptest](https://github.com/shekyan/slowhttptest)

一个用来模拟长时间连接的HTTP测试工具

- [Java IO](https://events.linuxfoundation.org/wp-content/uploads/2017/11/Accelerating-IO-in-Big-Data-%E2%80%93-A-Data-Driven-Approach-and-Case-Studies-Yingqi-Lucy-Lu-Intel-Corporation.pdf)
