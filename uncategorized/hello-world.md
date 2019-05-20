date: 2019-03-08
title: Hello World
---
所以终于有了一个不那么难看的个人博客了，首先要感谢一下[nginx](https://nginx.org), [hexo](https://hexo.io), [hexo-landscape-theme](https://github.com/hexojs/hexo-theme-landscape)和[disqus](https://disqus.com/)提供的出色软件/服务, 如果你想看一个内容一样，但是<del>比较丑</del>性冷淡的博客，[请戳这里](https://lijinpei.me/raw).

不过这个博客还有几点我不太满意的地方.

TODO:

- disqus只有翻墙才能使用(所以如果你没有在这篇文章下面看到disqus的框框，可能是因为disqus被墙了,你可以检查你的浏览器的web console里有没有无法加载https://lijinpei-me.disqus.com/embed.js之类的信息)
- 加一个阅读计数
- 加一个sitemap
- 加点广告(逃
- 把原来博客的内容迁移过来,看一下hexo deploy的工作流程: 目标是只在git中追溯_config.yaml,我写的博客的md文件,theme subrepo(很可能是我改过的theme).
- 保证一个博客文章的地址改变以后,disqus的内容不丢,现在landscape主题发给disqus的请求是根据博客文章的路径确定的，如果以后改变路径的话需要迁移一下.
- hexo似乎不太容易部署到两个不同的路径,一个克服办法是对两个路径分别生成内容再分别拷贝过去，另一个办法是利用nginx重定向路径A到路径B。我目前用的是第二个办法，但我希望能有办法从路径A和路径B访问同样的内容而不通过HTTP 重定向(这是一个好的做法吗?),硬盘上只有一份生成的文件，nginx为两个路径提供同样的文件(可能有文件中的相对/绝对路径引用的问题?). 注意要做到这一点要克服上面那个disqus路径的问题.
- Google Analytics似乎会[被firefox干掉](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Privacy/Tracking_Protection)，无所谓了.
Happy Hacking!

## Quick Start

### Create a new post

``` bash
$ hexo new "My New Post"
```

More info: [Writing](https://hexo.io/docs/writing.html)

### Run server

``` bash
$ hexo server
```

More info: [Server](https://hexo.io/docs/server.html)

### Generate static files

``` bash
$ hexo generate
```

More info: [Generating](https://hexo.io/docs/generating.html)

### Deploy to remote sites

``` bash
$ hexo deploy
```

More info: [Deployment](https://hexo.io/docs/deployment.html)

