> 本文翻译自：Split laps timer with RxSwift and RxCocoa: Part 2  
原文地址：http://rx-marin.com/post/rxswift-rxcocoa-timer-app-useWithLatest-bindings/  
作者：[Marin Todorov](http://www.underplot.com/)

---
在上个星期我发表的文章中，我曾经创建了一个拆分计时器应用程序，但是后来当我玩这个APP的时候，我注意到我应该使用一些办法来启动和停止计时器。  
本周我正在实现这个功能。  
我想到的第一件事情就是如何在我的APP中实现状态，因为定时器显然有两个不同的状态，**运行**和**不运行**。这让我想到了结合信号，映射，你知道的所有的好东西。  
如何你想要跟随我的步伐，你也可以下载我准备好的启动项目，它还是在上周博客写完时的状态，但我已经在用户界面上添加了几个按钮。  
![](http://rx-marin.com/images/latimer-new-ui.png)  
下载启动项目以便跟着我做：[rx_laptimer_starter.zip](https://github.com/qiuncheng/posted-articles-in-blog/tree/master/Demos)  
现在，让我们把所有的按钮都运行起来。  
我的第一个想法是尝试生成一系列值来描述定时器当前的状态。启动按钮将产生`true`值，停止按钮将产生`false`值。当将他们两者合并时，我会得到每次状态改变时发出的一个序列。  
`o---- (play tap) true--- (stop tap) false --- (play tap) true --->`  
所以在`viewDidLoad`的顶部，我创建了一个新的`Observable`, 像这样:  
```
let isRunning = Observable
      .merge([btnPlay.rx.tap.map({ return true }), btnStop.rx.tap.map({ return false })])
      .startWith(false)
      .shareReplayLatestWhileConnected()
```
首先，我将`btnPlay`上的点击转换成`true`, 同时`btnStop`上的点击转换成`false`，然后将它们两合并。  
`Observable`是以一个`false`开始，为用户提供方便启动计时器的机会。  
我打印了新的`Observable`发出的值，并对结果感到非常满意。  
```
isRunning.subscribeNext({state in
    print(state)
}).addDisposableTo(bag)
```
每次点击了播放或停止按钮时，代码在控制台中都会打印`true`或`false`, Neato！  
现在看起来非常容易就可以将`Observable`绑定到`button`的`rx_enabled`属性上，实际上也可以使UI改变了`timer`(定时器)的状态。当`timer`(定时器)没有运行时，我可以隐藏时间拆分按钮。  
而且由于一些控件需要在定时器运行时就要被启用，而其他控件需要在启用时才会被启用。这样一来，我就可以使自己成为另一个`Observable`，并将其控制如下：  
```
let isntRunning = isRunning.map({running in !running}).shareReplay(1)

isRunning.bindTo(btnStop.rx_enabled).addDisposableTo(bag)
isntRunning.bindTo(btnLap.rx_hidden).addDisposableTo(bag)
isntRunning.bindTo(btnPlay.rx_enabled).addDisposableTo(bag)
```
定时器运行时停止按钮可以点击，定时器暂停时，播放按钮可以点击。  
我真的很喜欢这种代码，没有`if`没有`switch`；一旦你让代码运行了起来，就很难搞砸。而且没有空间来引入错误，一切都是气密的。  
该应用现在开始隐藏了拆分按钮，只有播放和暂停按钮如下：  
![](http://rx-marin.com/images/laptimer-play.png)  
此外你可以点击播放一次，因为他在你点击了之后立即会被禁止点击。How cool!.  
现在我的问题是，即使UI已经响应了`timer`的不同状态, 但是定时器timer并不关心它们中的任何一个。  
我研究了一下定时器的`RxSwift`具体实现，但是没有找到一种方式来暂停它(我猜，它无法实现这种状态，谁知道呢？)，这就是为什么我以为我会将定时器直接绑定到`UI`,并实现自己的计数器。  
当时我的计时器看起来是这样的：  
```
timer = Observable<Int>.interval(0.1, scheduler: MainScheduler.instance)
```
嗯，我想，我只需要以某种方式组合`isRunning`和定时器，并在`isRunning`为`false`时过滤可观察的输出。  
所以我做了以下操作：我添加到现有的计时器一个运算符来结合它与最新的`isRunning`值：  
`.withLatestFrom(isRunning, resultSelector: {_, running in running})`  
你可以看到我只是忽略了计时器发出的值，因为我从不使用它，并从`withLatestFrom`返回不变的输入参数。
`(Int, Boolean) -> withLatestFrom -> Boolean`  
接下来，我可以简单的使用`filter`来过滤掉停止时计时器发出的`Observable`值。
`.filter({running in running})`
最后最重要的是我不得不附上一个`counter`, 但这已经是我知道的就像`scan`一样的东西啦。
```
.scan(0, accumulator: {(acc, _) in
    return acc+1
})
```  
上面的`scan`是计算定时器触发的次数，而`Running`是`true`（这才正是我想要的）。  
最后，我必须设置初始值显示在UI中，并在所有观察者之间共享结果：  
```
 .startWith(0)
 .shareReplayLatestWhileConnected()
```
为了完整代码，我增强了`timer Observable`, 如下所示：
```
timer = Observable<Int>.interval(0.1, scheduler: MainScheduler.instance)
    .withLatestFrom(isRunning, resultSelector: {_, running in running})
    .filter({running in running})
    .scan(0, accumulator: {(acc, _) in
        return acc+1
    })
    .startWith(0)
    .shareReplayLatestWhileConnected()
```
这是一个包装:], 现在我的应用程序有一个有状态的拆分时间也正常实现，但是没有使用一个`if`。    
![](http://rx-marin.com/images/laptimer-2-final.gif)    
您可以下载完成的项目，并在这里尝试：[rx_laptimer.zip](https://github.com/qiuncheng/posted-articles-in-blog/tree/master/Demos).  
希望这篇文章是有帮助的，如果你想联系你，你可以找到我在这里[Twitter](https://twitter.com/intent/follow?original_referer=http%3A%2F%2Frx-marin.com%2Fpost%2Frxswift-rxcocoa-sample-split-laps-timer%2F&ref_src=twsrc%5Etfw&region=follow_link&screen_name=icanzilb&tw_p=followbutton)

> 注： 原文提供的代码下载地址还不是Swift 3的，所以我在这里已经更改了原作者提供的地址。代码经过`Xcode8.2.1`测试，完全可以测试通过。  
对于英语好的同学，推荐阅读作者的英文原文。 

