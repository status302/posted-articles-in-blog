> 本文翻译自http://stackoverflow.com/questions/24320347/shall-we-always-use-unowned-self-inside-closure-in-swift  主要是对回答者[drewag](http://stackoverflow.com/users/661853/drewag)的翻译  
提问者：[Jake Lin](https://github.com/JakeLin)   
译者：[vsccw](https://vsccw.com)  
### 问题：  
Shall we always use [unowned self] inside closure in Swift？  
我们总是需要在Swift闭包内使用[unowned self]吗？
![图片描述](https://i.stack.imgur.com/Jd9Co.png) 
上图来自问题。

---  
### 回答：  
不是的，在有些时候，你会不想使用[unowned self]。有时你想要闭包捕获自我，以确保他被调用时依然存在。
### 举例：进行异步网络请求
如果你正在做一个异步的网络请求，你希望闭包在请求完成时保留自己。该对象可能已经被销毁，但是你依然想要处理请求完成情况。
### 那么什么时候使用[unowned self]与[weak self]呢？
你想要使用[unowned self]与[weak self]唯一的时间就是当你创建了一个[**循环引用**](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html#//apple_ref/doc/uid/TP40014097-CH20-XID_61)的时候。循环引用指的是对象互相持有彼此（也有可能通过第三方中介等），他们永远不会被释放，因为他们都确保彼此*拥有对方*。  
在闭包的特定情况下，你仅仅需要意识到闭包中引用的任何变量，都被闭包所拥有。只要闭包存在的情况下，这些对象也都会存在。阻止这种互相拥有的唯一办法就是使用[unowned self]和[weak self]。因此，如果一个类拥有一个闭包，并且该闭包捕获了对该类的强引用，那么在该类和闭包之前就有一个*引用循环*。这当然也包括如果一个类拥有 拥有闭包的某些东西（其实可以理解中间的第三者）。
### 从视频截图中例子说起
在幻灯片的例子中，`TempNotifier`通过`onChange`成员变量拥有闭包，如果他们没有将`self`声明为`unowned`, 该闭包也会拥有`self`， 由此造成了*循环引用问题*。
### `unowned`与`weak`的不同
**`unwoned`与`weak`的区别点在于：`weak`声明为可选，而`unowned`则不是。通过将其声明为`weak`，在某种程度上你可以处理他可能在闭包内为nil的情况。如果你试图访问一个`unowned`变量，他恰好为nil, 这会崩溃整个程序，所以仅仅在你知道该对象和闭包一直存在且不为空的情况下去使用`unowned`。**

> 译者注：具体什么是循环引用，可参考文中链接。