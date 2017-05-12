> 本文翻译自：Custom convenience operators with RxSwift, Part 2  
> 原文地址： http://rx-marin.com/post/rxswift-rxcocoa-custom-convenience-operators-part2/  
> 作者：[Marin Todorov](http://www.underplot.com/)

---
### 介绍
我对上周在自定义`convenience operators(part 1)`的帖子中收到一些很好的反馈意见，所以我很高兴发布(part 2)，对于那些正在研究RxSwift的人来说，我希望能更有趣。
不用多说，我们在代码中潜水吧。
#### 更好的`negate()`运算符
首先，我有一个比上周`negate()`更好的运算符。我自己写的是一个非常简单的功能，看起来像这样：
```
extension Observable where Element: BooleanType {
  public func negate() -> Observable<Bool> {
     return map {value in !value}
  }
}
```
没有比这更简单的啦，对吧？在一行代码中映射一个值，就是这样（不过小心，这是一个棘手的问题）。
[@tailec](http://www.tailec.com/)在Slack上@我，向我展示了他的这个操作符的版本，这确实比我的好：  
```
extension Observable where Element: BooleanType {
    public func negate() -> Observable<Bool> {
        return map(!)
    }
}
```
对！自从`!`具有单个参数的功能，您可以简单地与map一起使用。那个代码肯定比我的好，我也会在我自己的项目中使用这个版本。谢谢[Pawel](那个代码肯定比我的好，我也会在我自己的项目中使用这个版本。谢谢Pawel。
)。
> 请大家，如果你看到我在这里发布的东西，有可以改进的地方，请立刻联系我，像Pawel这样，并帮助获得一些令人敬畏的`rx`代码在一起！
#### filterNegatives()
我正在查看我当前的项目代码，并尝试识别重复的模式，我可以轻松地外包给一个`convenience operator.`。
我注意到我几乎没有`Bool Observables`，有时只有在发现真实价值时才感兴趣。例如，如果我们从我的`lap timer`帖子中获取代码：
```
let isRunning = [btnPlay.rx_tap.replaceWith(true), btnStop.rx_tap.replaceWith(false)]
  .toObservable()
  .merge()
  .startWith(false)
  .shareReplayLatestWhileConnected()
```
其根据播放和停止按钮上的点击事件而产生：
`true — false — true — true –>`
只能观察播放的点击事件呢？ （当然除了订购播放按钮）
因为我想要的是基本上摆脱了我写的所有虚假的价值：
```
extension Observable where Element: BooleanType {
  public func filterNegatives() -> Observable<Bool> {
     return map {value in value.boolValue}
  }
}
```
很简单的代码，它可以工作很好，也很容易阅读！
#### replaceNilWith(_)
这是一个简单的操作符来实现的。我有几个`Observable`发出可选值，但是我实际上想得到一个给定的默认值，而不是nil。我只需要映射到一个简单的条件，如下面检查的nil值：
```
extension Observable {
  func replaceNilWith(value: Element) -> Observable<Element> {
     return map {element in element == nil ? value : element}
  }
}
```
请注意，`observable`的元素仍然是可选的`<Element>`类型，但是你永远不会获得一个`nil`值 - 您将获得默认值。
#### filterOut(_)
与此同时我充满了很大的动力，我决定也写一个过滤器来过滤掉某些值。由于该方法与之前完全相同，我将在此添加代码：
```
extension Observable where Element: Equatable {
    public func filterOut(targetValue: Element) -> Observable<Element> {
        return self.filter {value in targetValue != value}
    }
}
```
关于这段代码有意思的地方在于为了能够识别序列中的不符合规定的值，它必须是相等的，因此你必须将filterOut运算符限制为仅发布Equatable元素的可观察值。  
当然这仅仅类似于在Swift的公园里漫步，你可以添加`where Element: Equatable`在你的`extension`中。  
关于`filterOut(_)`最好的一点是每当我有一个可观察的发射可选值，每当我有一个可观察的发射可选值，例如`Observable <Bool?>`，我可以确保不会像这样排出零值：  
```
optionalBoolSequence.filterOut(nil)
```
可观察的元素的类型仍然是`Observable<Bool>`，但是现在我确信`observer`从不会发出一个`nil`值。  
#### unwrap(_)
到目前为止，我已经有两个`convenience operators`来帮助我在序列中摆脱`nil`，但是得出的`element`依然是`Optional`。  
好吧，我想，实际上用Swift协议黑魔法解析一个可观察的元素并不是那么难！  
好吧，我完全错了吗？  
![](http://rx-marin.com/images/fry-wrong.png)  
我最初的认识是`Optional`不是协议。所以我无法做任何协议黑魔法。啊!  
`Optional`实际上是枚举。是的 - 当`Swift 1.0 alpha`出来时，这听起来感觉很刺激，但是老实说，我期望它是一个协议或更灵活的东西。  
不管怎样，因为可选不是协议，我无法创建与可选元素匹配的Observable的扩展。Glup  
我在Slack上与[Matthijs]()https://twitter.com/mhollemans和[Ross O’Brien](https://twitter.com/narrativium)进行了一个非常长的对话，直到最后我可以弄清楚...  
首先我必须自己定义一个可选的协议。我的协议必须定义两种方法：  
- 一个可以用来检查当前值是否为nil(猜猜是什么, 只是简单将自己和nil进行对比呀！！！)
- 另一个方法可以将self从Optional<Type>转换到Type  
我不得不围困的一个大问题是：该转换后的值是什么类型？我不知道这在我的协议中该怎么办，所以我不得不定义一个具体实现将设置的类型。
结果我这样做：
```
protocol Optionable {
  typealias WrappedType
  func unwrap() -> WrappedType
  func isEmpty() -> Bool
}
```
酷，现在我有了一个`protocol`，然后我可以以`extension`的形式向`Observable`添加方法了。  
但首先我必须使可选枚举遵循Optionable。所以可选通过Wrapped来显示包装值的类型，这是可选和我的Optionable协议之间的魔术性的融合发生的地方。  
以下是可选的声明：  
```
public enum Optional<Wrapped> : _Reflectable, NilLiteralConvertible {...}
```
以下是我如何将“Optionable”功能连接到任何具体可选值的类型：  
```
extension Optional : Optionable {
    typealias WrappedType = Wrapped
}
```
哈！ （Matthijs和Ross再一次帮助了我很多，解开了所有这一切，我不得不说，在线上很少有关于协议魔法和相关类型的信息）  
现在我也可以在扩展中添加两个方法的实现：  
```
func unwrap() -> WrappedType {
    return self!
}

func isEmpty() -> Bool {
    return !(flatMap({_ in true})?.boolValue == true)
}
```
你猜到了 - 编码`unwrap()`是很直接的，但`isEmpty()`引起我严重的头痛。  
令我惊奇的是，我知道在这里重复一遍，`Optional`不给你检查是否为空。  
起初我来了这个天真的实现：  
```
func isEmpty() -> Bool {
  switch self {
    case .None: return false
    case .Some(_): return true
  }
}
```
嗯，让我告诉你：这个行不通，虽然你跟我讲这是可行的，但是实际上不可行，在这种情况`.None`下，由于一些原因，它永远不会返回。  
所以我不得不采取一些艰难的决定，我再次看到可以在`Optional`找到的所有东西  
![](http://rx-marin.com/images/optional-docs.png)  
**并不是很多，并不是很多。**  
等等，`flatMap？`结果是当然可以，以下是`Optional`的`flatMap`上的（完整）文档：  
如果`self`为`nil`，则返回`nil`，否则返回`(self！)`。  
我使用`flatMap`方法重写了`isEmpty`方法：
```
func isEmpty() -> Bool {
    return !(flatMap({_ in true})?.boolValue == true)
}
```
现在（最后）我可以添加到Observable的扩展，相比之下，我已经经历过的所有其他事情...让我们说并不是那么困难：  
```
extension Observable where Element : Optionable {
  func unwrap() -> Observable<Element.WrappedType> {
    return self
      .filter {value in
        return !value.isEmpty()
      }
      .map {value -> Element.WrappedType in
        value.unwrap()
      }
  }
}
```
这段代码有几点值得注意：  
- 我将`Observable`类型与`Optional`匹配。可选实现可选，但是如果任何其他类型的`unwrap()`也可以正常使用。
- `unwrap()`接收一个`Element`类型值并输出`Element.WrappedType`，因此对于`Int?`输出`Int`，为`NSDate?`输出 NSDate  等
- 为什么不使用`filterOut(nil)`来摆脱`nil`？ `filterOut(_)`适用于`Equatable`值，在某些情况下，`Element.WrappedType`可能不相等
- 我不得不明确地设置我的`map`闭包的返回类型，因为这点事情对于Xcode来说有点太抽象了
现在我们看看完整的实现（如果你可以想办法简化这个，请让我知道，我仍然认为应该有一个更简单的方法）  
```
protocol Optionable
{
  typealias WrappedType
  func unwrap() -> WrappedType
  func isEmpty() -> Bool
}

extension Optional : Optionable {
  typealias WrappedType = Wrapped
  func unwrap() -> WrappedType {
    return self!
  }
    
  func isEmpty() -> Bool {
    return !(flatMap({_ in true})?.boolValue == true)
  }
}

extension Observable where Element : Optionable {
  func unwrap() -> Observable<Element.WrappedType> {
    return self
      .filter {value in
        return !value.isEmpty()
      }
      .map {value -> Element.WrappedType in
        value.unwrap()
      }
  }
}
```
这是有趣的一天！公平地说我也学到了相当多的协议，关联类型等。  
后来我正在和[@fpillet](https://twitter.com/fpillet)交谈，他在这里分享了一下：  
```
someOptionalSequence
  .flatMap { $0 == nil ? Observable.empty() : Observable.just($0!) }`
```
这是一个可以直接在你的`Observable`的`Optional<Element>`类型里。它与我的`unwrap()`操作符几乎相同，但是它的实现方式更短，因为`flatMap`闭包不需要指定它的返回类型 - 它将它留给Xcode从上下文获取。  
我仍然喜欢我自己的操作符 - 我觉得它的可读性更高，它给编译器增加了更少的压力：  
`someOptionalSequence.unwrap()`
![](http://rx-marin.com/images/unwrap-doge.png)
### 总结
创建你自定义的操作符是非常有趣的，代码更易读，引入错误的机会较少，没有任何错误。  
我已经在计划下一篇文章：创建自己的`Cocoa`绑定, 如果你已经为UIKit类做了一些很酷的自定义绑定，或者任何其他有趣的可绑定属性让我知道。Woot！  
你知道一个更好的办法吗？看到一个bug？[在Twitter上@我](https://twitter.com/intent/follow?original_referer=http%3A%2F%2Frx-marin.com%2Fpost%2Frxswift-rxcocoa-custom-convenience-operators-part1%2F&ref_src=twsrc%5Etfw&region=follow_link&screen_name=icanzilb&tw_p=followbutton)


















