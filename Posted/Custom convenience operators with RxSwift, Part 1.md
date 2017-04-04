> 本文翻译自：Custom convenience operators with RxSwift, Part 1  
原文地址： http://rx-marin.com/post/rxswift-rxcocoa-custom-convenience-operators-part1/   
作者：[Marin Todorov](http://www.underplot.com/)

---
## 介绍
就像学习一门新的语言一样，你需要建立一个字典`(注1：原文：Dictionary, 可以理解为字典一样的东西)`来开始了解语言的工作原理。学习`RxSwift`，你必须学习`Rx`运算符，并且最终将他们全部掌握。  
然后，一旦你对语言通用部分有了很好的理解能力，就可以开始想出新的想法，与此同时可以提高你**演讲**`(注2: 原文expressiveness，可以理解为 代码的表达力 更合适)`的表现力和便利性。  
我上周遇到了同样的事情，我第一次觉得我正在使用`RxSwift`完成工作，因为我了解了很多`operators`。当然，我希望创建自定义的`convenience operators`，虽然他不会做基本的新的事情，但会帮助我更好更清楚的表达自己。  
### `replaceWith(value): Replace any element with a constant(用常量替代任何元素)`
当我只想对一组事件作出反应时，我将替代发出的实际值，以便我可以将两个或更多个Observables合并成一个流并观察该流。  
以下的代码是[上周发布](https://vsccw.com/2017/03/29/rxswift-split-laps-timer-02/)的，并观察了定时器应用的开始和停止按钮上的点击：  
```
let isRunning = Observable
      .merge([btnPlay.rx.tap.map({ return true }), btnStop.rx.tap.map({ return false })])
      .startWith(false)
      .shareReplayLatestWhileConnected()
```
我正在看这一大块代码，并思考着应该有更加简洁，更加可读性的方式来表达`map:`这部分。我在这里做的两个`Observable`实际上是忽略实际的值，并用一个常量替换它。  
所以我深入研究了一下`RxSwift`代码，并根据我在那里找到的写了下面这段**辉煌**`(注3：原文brilliant，其实作者是反义，可以理解为难看的)`的代码：
```
func replaceWith<R>(value: R) -> Observable<R> {
    return Observable.create { observer in
        let subscription = self.subscribe { e in
            switch e {
            case .Next(_):
                observer.on(.Next(value))
            case .Error(let error):
                observer.on(.Error(error))
            case .Completed:
                observer.on(.Completed)
            }
        }
        return subscription
    }
}
```
我创建并返回一个新的`Observable`，并完善了`Error`和`Completed`事件。但用常量值来替换`Next`事件的值。但是这样好吗?  
看起来像是宏伟的代码其实是有点过了。我的意思是，毕竟我只想`map`任何类型的任何值到一个常量，当你这样说，几乎不用写代码。所以最后我重写了这样的代码：
```
extension ObservableType {
    func replaceWith<R>(value: R) -> Observable<R> {
        return map { _ in value }
    }
}
```
正如你所看到的，我并没有对整个事情感到疯狂，只是从字面上看，我想在`ObservableType`的一个扩展方法中重用并将其抽象出来。  
从文章的开头的代码块现在看起来是这样的：
```
let isRunning = Observable
      .merge([btnPlay.rx.tap.replaceWith(true), btnStop.rx.tap.replaceWith(false)])
      .startWith(false)
      .shareReplayLatestWhileConnected()
```

很棒。拥有自己的自定义`convenience operator`使得代码更不容易出现错误，(闭包中不用写多余的代码)，并且更加易于阅读。  
在这一点上，我开始怀疑我自己，这简直太好了，不过不得不说真话的话，我一定是做错了什么:)  
然而事实证明，许多人在代码的过程中都有过准确地自定义`operators`，他显然解决了一个常见的问题。  
然后我有点疯狂，决定在兴趣的驱动下进一步探索我可以深入到那里。  
### replaceWithDate(): 将时间戳替换为最新值 
由于我的热情已经被`replaceWith()`点燃了，我认为从`convenience operator`中获取可观测序列中最新元素的时间戳是很有趣的。  
在这个具体的情况下，我将使用常量替代具体的当前日期：   
```
extension ObservableType {
    func replaceWithDate<R>(value: R) -> Observable<NSDate> {
        return map { _ in NSDate() }
    }
}
```
现在我可以将`Observable`中的最新值绑定到`Label`，并在另一个`Label`中显示该值的时间戳，如下所示：
```
let count = Observable<Int>
    .interval(3, scheduler: MainScheduler.instance)
    .shareReplay(1)

count.map {counter in "\(counter)"}
    .bindTo(label1.rx_text)
    .addDisposableTo(bag)

count.replaceWithDate()
    .map {$0.description}
    .bindTo(label2.rx_text)
    .addDisposableTo(bag)
```
这是结果（等待几秒钟可以看到数字在增加）：  
![](http://rx-marin.com/images/latest-date.gif)
### negate()：取消元素的值
接下来我注意到有时我需要将一个`Observable`绑定到一个按钮的`rx.enabled`属性，有时候要绑定到`rx.hidden`。在编写绑定代码时，我不得不使用许多`map {value in！value}`，这使得我的代码很难以阅读。  
> 如果你查看了上周的文章，你将看到，为了提高可读性，我最终有两个可观察值：一个称为`isRunning`，另一个`"isntRunning"`。  

在阅读了一些`RxSwift`的代码之后，我学会了如何向某个类型的`Observable`添加一个运算符。在我遇到的这个情形中，我想要给只产生`Bool`的`Observables`添加`negate() operator`。  
`Observable`将其元素的类型暴露为Element，我可以很容易地将它与`BooleanType` `(Swift FTW!)`进行匹配：
```
extension Observable where Element: BooleanType {
    public func negate() -> Observable<Bool> {
        return map {value in !value}
    }
}
```
Sweet - 感谢协议扩展与相关类型！现在我可以很容易地编写代码：
```
active.bindTo(btnStart.rx.enabled).addDisposableTo(bag)
active.negate().bindTo(btnStart.rx.hidden).addDisposableTo(bag)
```
当代码发出`true`元素时，此代码将同时启用和显示该按钮。Pretty sleek eh?    
今天文章中的代码，我稍后会添加到我的项目中：  
```
extension Observable where Element : SignedIntegerType {
    public func negate() -> Observable<E> {
        return map {value in -value}
    }
}
```
现在，`negate()`也可在其他上下文中工作。如果您在`Observable<Bool>`上使用它，它将应用元素逻辑的`not`值；如果您在`Observable<Int>`上使用它，则会产生元素的负值。Cool！  
## 结论
创建自己的`convenience operator`是非常棒的。它可以使代码更易读，引入错误的几率也会减少，并且没有任何错误。  
在我的下一篇文章中，我将探索更多的`operator`。你想分享你的任何一个吗？  
你知道一个更好的办法吗？或者看到一个bug？[在Twitter上@我](https://twitter.com/intent/follow?original_referer=http%3A%2F%2Frx-marin.com%2Fpost%2Frxswift-rxcocoa-custom-convenience-operators-part1%2F&ref_src=twsrc%5Etfw&region=follow_link&screen_name=icanzilb&tw_p=followbutton)

> 注： 原文提供的代码下载地址还不是Swift 3的，所以我在这里已经更改了原作者提供的地址。代码经过`Xcode8.2.1`测试，完全可以测试通过。  
对于英语好的同学，推荐阅读作者的英文原文。 