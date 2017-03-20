> 本文翻译自：http://rx-marin.com/post/rxswift-rxcocoa-sample-split-laps-timer/   
作者：[Marin Todorov ](http://www.underplot.com/)
----
我正在浏览[RxMarbles](http://rxmarbles.com/)，完全被[`sample`](http://rxmarbles.com/#sample)函数所困扰。流程图看起来很随机：  
![marble diagram](http://rx-marin.com/images/marbles-sample.png)  
起初我想 - “嘿，第二个序列正在被完全忽略！”，但是在我阅读之后，我发现：  
    `第一个序列的元素是由样品发出的，而第二个序列的元素决定样品发出的时间，所以在某种程度上是-实际上A,B,C,D确实被完全忽略。`  
当我明白了`sample`做了些什么，我开始想知道这个功能是否有实际的用处:]  
这让我想创建一个拆分计时器(注: `split lap timer`)应用程序来测试`sample`可以为我们做什么。在完成的项目中，我有一个定时器发出时间值(也就是一个序列)，同时我也想要抓住(注: grap)或者`sample`每一次用户点击(是另一个序列)按钮的反应值。  
下面是应用程序设置的流程图：  
![marble diagram when app setup](http://rx-marin.com/images/sample-dia.png)  
这是完成后的应用程序的样子：  
![finished](http://rx-marin.com/images/laptimer-finished.png)  
让我们开始构建这个应用吧:]  
下面是我想要的拆分计时器应用的运行与功能：
1. 在程序启动时就启动计时器
2. 以 `MM:SS:MS` 的形式显示运行时间
3. 当用户点击了按钮`Split Lap`的时候添加一条拆分时间值
4. 以一个列表的形式展示拆分时间
5. 以列表头的形式展示拆分时间数目总和
### 1. 启动计时器
像我在[前一篇文章](http://rx-marin.com/post/rxswift-timer-sequence-manual-dispose-bag/)中关于手动处理包内容那样，我添加一个`timer`。  
```
var timer: Observable<Int>!
```
同时在`viewDidLoad`中让它每1/10秒运行一次。（我选择只显示一位数毫秒，所以不需要频率更高:]）
```
//create the timer
timer = Observable<Int>.interval(0.1, scheduler: MainScheduler.instance)

timer.subscribeNext({ msecs -> Void in
  print("\(msecs)00ms")
}).addDisposableTo(bag)
```
这会使计时器运行，并填满控制台：
```
000ms
100ms
200ms
300ms
400ms
500ms
600ms
700ms
800ms
900ms
1000ms
1100ms
```
酷，这很好:](你一定会想，“好吧，我已经知道如何做这个了”)
### 2. 显示当前已过去时间
这也是我已经知道如何去做的部分。首先我写了一个小的函数，该函数会将已过去的时间格式化成想要的字符串。
```
func stringFromTimeInterval(ms: NSInteger) -> String {
  return String(format: "%0.2d:%0.2d.%0.1d",
    arguments: [(ms / 600) % 600, (ms % 600 ) / 10, ms % 10])
}
```
然后回到`viewDidLoad`，我使用该函数绑定计时器到通过`Interface Builder`创建的Label中。
```
//wire the chrono
timer.map(stringFromTimeInterval)
  .bindTo(lblChrono.rx.text)
  .addDisposableTo(bag)
```
我真的很喜欢代码运行的步骤，下面是代码中一步步发生的事情：
```
timer -> 1,2,3 -> stringFromTimeInterval -> "string", "string" -> lblChrono
```
函数式的代码非常棒，因为我已经取得了两个巨大胜利，我可以很容易重用`stringFromTimeInterval`，然后我也可以写一些非常简单的测试代码。  
与此同时，定时器`label`已经成功显示了当前运行的时间：   
![当前运行时间](http://rx-marin.com/images/laptimer-label.png)  
### 3. 当用户点击了`Split Lap`按钮的时候，抓取当前拆分的时间
在这里我应该可以达到我的终极胜利：使用`sample`。前几次尝试并没有让我迈出大步，直到我意识到`rx.tap`也是一个`Observable`。  
> Duh，一切都是`Observable`：    

现在只剩下`timer`调用`sample`这一个问题了，并提供作为控制序列的按钮的属性`rx.tap`，就像这样：`timer.sample(btnLap.rx.tap)`，怎么去做？（Whaaat?）  
现在我每次点击按钮`sample`都会发出`timer`产生的最新值。由于我对数字不感兴趣，但是在格式化字符串的时候我再次将结果使用`stringFromTimeInterval`转换。  
因为我需要创建一个分离的时间列表，我使用`scan`。实际上我第一次是想用`reduce`，因为我想在列表中累加值，但是后来意识到，我需要产生一个序列，同时这个序列发出每个新值得列表。因此我意识到了我得使用`scan`。
```
let lapsSequence = timer.sample(btnLap.rx_tap)
    .map(stringFromTimeInterval)
    .scan([String](), accumulator: {lapTimes, newTime in
        return lapTimes + [newTime]
    })
    .shareReplay(1)
```
所以，每次`sample`发出新的拆分时间时，`scan`会扫描到目前为止所有拆分时间的数组。  
不知道如何解释`scan`更简单，但是我会尝试：在`RxSwift`中的任何时候，如果你正想使用`reduce`，那么你也可以使用`scan`代替:]
### 4. 显示到目前为止所有的拆分时间表
OK, 所以我得到了`lapsSequence`发出的拆分时间数组。在参考了`RxExample`之后，我们就可以操作`UITableView`了。
```
//show laps in table
lapsSequence
        .bindTo(tableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { (row, element, cell) in
        cell.textLabel?.text = "\(row + 1)) \(element)"
        }
        .disposed(by: bag)
.addDisposableTo(bag)
```
同时我的APP已经正常工作了。  
![Working](http://rx-marin.com/images/laptimer-table.png)  
我每一次点击`Split Lap`按钮，都会添加一条拆分时间到TableView上。Sweet~
### 5. 在TableView标题上显示拆分时间总数
这部分是让我最失望的。因为没有一个绑定我可以用在TableView的Header上，同时我又不想添加数据源，这样会使代码复杂化。  
于是我突然想到在我的控制器中添加一个Label，并将它作为TableView的header，然后将拆分次数总数绑定到这个label的`rx.text`上。  
所以我添加一个label到视图控制器上：
```
let tableHeaderView = UILabel()
```
然后是一个扩展，并将该label设置为TableView的header:
```
extension ViewController: UITableViewDelegate {
  func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return tableHeaderView
  }
}
```
我知道如何设置TableView的代理到ViewController这个类中（让我们回到ViewDidload中）：
```
//set table delegate
tableView
  .rx.setDelegate(self)
  .addDisposableTo(bag)
```
现在又出现了变况，我不得不将`lapsSequence`从数组映射到单个字符上（例如：5次），并将该字符串绑定到TableView header上。
我过度兴奋地想使用`scan`,但是代码确实有些不优雅。后来在RxSwift slak问了[KrunoslavZaher](), 他启发了我，因为我有一个数组，这样我就可以使用`map`将其转换成字符串。
下面是最终在`viewDidLoad`中的代码：
```
//update the table header
lapsSequence.map({ laps -> String in
    return "\t\(laps.count) laps"
})
.startWith("\tno laps")
.bindTo(tableHeaderView.rx_text)
.addDisposableTo(bag)
```
因为`lapsSequence`发出的是所有拆分时间的数组，每次发出一个新的拆分时间，我只取该数组，并返回一个包含元素数量的字符串。
此外，我将初始值设置为`no laps`, 这样很好。我将所有内容直接绑定到`tableHeaderView.rx_text`上。  
这是完整的应用程序！  
![](http://rx-marin.com/images/laptimer-finished.png)  
您可以下载完成的项目，并在这里尝试：[rx_laptimer.zip](https://github.com/qiuncheng/posted-articles-in-blog/tree/master/Demos).  
希望这篇文章是有帮助的，如果你想联系你，你可以找到我在这里[Twitter](https://twitter.com/intent/follow?original_referer=http%3A%2F%2Frx-marin.com%2Fpost%2Frxswift-rxcocoa-sample-split-laps-timer%2F&ref_src=twsrc%5Etfw&region=follow_link&screen_name=icanzilb&tw_p=followbutton)

> 注： 原文提供的代码下载地址还不是Swift 3的，所以我在这里已经更改了原作者提供的地址。代码经过`Xcode8.2.1`测试，完全可以测试通过。  
对于英语好的同学，推荐阅读作者的英文原文。
