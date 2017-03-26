> 本文翻译自：Split laps timer with RxSwift and RxCocoa: Part 2  
原文地址：http://rx-marin.com/post/rxswift-rxcocoa-timer-app-useWithLatest-bindings/  
作者：[Marin Todorov](http://www.underplot.com/)

---
在上个星期我发表的文章中，我曾经创建了一个拆分计时器应用程序，但是后来当我玩这个APP的时候，我注意到我应该有一些办法来启动和停止计时器。  
本周我正在实现这个功能。  
我想到的第一件事情就是如何在我的APP中实现状态，因为定时器显然有两个不同的状态，运行和不运行。这让我想到了结合信号，映射，你知道的，所有的好东西。  
如何你想要跟随，你可以下载我准备好的启动项目，他还是在上周博客写完时的状态，但我已经在用户界面上添加了几个按钮。  
![](http://rx-marin.com/images/latimer-new-ui.png)  
下载启动项目以便跟着我做：[rx_laptimer_starter.zip]()  
现在，让我们把所有的按钮都运行起来。  
我的第一个想法是尝试生成一系列值来描述定时器当前的状态。