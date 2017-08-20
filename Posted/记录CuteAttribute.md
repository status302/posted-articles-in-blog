上周日几乎花了一天的时间把`CuteAttribute`这个工具从`Cute`这个工程中取出来，完善发布到Github上。说实话在很早之前就见到`Typeset`这个项目，不过那时因为对`NSAttributedString`使用较少，所以就没有深入研究`Typeset`。最近由于公司需求中需要使用`NSAttributedString`来做一些处理，加上本身不管是`Objective-C`还是`Swift`都比较难使用的`NSAttributedString`方式，所以就想着去寻找一个可以替代这种难写方式的东西。本来首先了解到的是`Typeset`，不过苦于对于Swift项目来说，大量使用`Objective-C`的`Block`简直是天灾。但又非常渴望这种处理`NSAttributedString`方式，索性就自己来搞了。  
首先在一开始的设计上，使用了swift中三方框架常用的`.xx`的方式，比如`RxSwift`中的`.rx`方式，`Kingfisher`中的`.kf`方式。所以`CuteAttribute`采用了`.cute`方式，(:
## 实现这种方式很简单，总结一下，大致需要三个步骤：
### 定义一个拥有可兼容多个类型属性的协议
```
public protocol CuteAttributeable {
    associatedtype Attributeable
    var cute: Attributeable { get }
}
```
这里的关键字`associatedtype`表示在protocol中代指一个确定类型并要求该类型实现指定方法。（其实就是给protocol添加泛型的关键字。）  
在这里定义了cute属性，需要遵守`CuteAttributeable`的类型去实现，并通过`Attributeable`指定其类型。
### 声明一个类，其中有一个泛型`Base`
```
public final class CuteAttribute<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}
```
在这里为了不让该类拥有子类，或者说不让该类被继承，添加了关键字`final`。  
该类中的`base`是`Base`类型。
### 给之前定义的protocol添加默认实现
```
public extension CuteAttributeable {
    public var cute: CuteAttribute<Self> {
        get { return CuteAttribute(self) }
    }
}
```
从上面的那段代码也可以看出，实际上是将之前定义的协议和类进行了结合。任意遵循了CuteAttributeable的类型都有cute属性。  
具体的`.cute`实现就是这么简单，当我们在给系统的方法添加extension的时候，只需要让系统的该类遵循CuteAttributeable就OK了。  
比如我们这里`extension NSMutableAttributedString: CuteAttributeable { }`就是给`NSMutableAttributedString`添加了`cute`属性。  
另外这里我们还给String、NSString、NSAttributedString也添加了cute属性，不过是通过另外一种方式实现。具体代码如下：  
```
public extension NSString {
    public var cute: CuteAttribute<NSMutableAttributedString> {
        return CuteAttribute(NSMutableAttributedString(string: string))
    }
}
```
以上提到的主要是自定义`.cute`这种方式，那么既然有了这种自定义，就应该有相应的实现方式。最简单的方式就是通过给`CuteAttribute`类添加`extension`的方式来实现。
```
public extension CuteAttribute where Base: NSMutableAttributedString {
    /// 在这里添加实现方式：方法、属性等。
}
```
## 其次是给`NSMutableAttributedString`添加扩展，来具体实现我们的功能部分。
在这里考虑多添加的属性还比较多，所以以给`NSMutableAttributedString`添加`range(_:)`为例。具体的代码如下：  
```
public extension CuteAttribute where Base: NSMutableAttributedString {
    
    public func range(_ range: NSRange) -> CuteAttribute<Base> {
        assert(base.string.nsrange >> range, "range should be in range of string.")
        self.ranges = [range]
        return self
    }
    
    internal(set) var ranges: [NSRange] {
        get {
            let defaultRange = NSRange(location: 0, length: base.length)
            return objc_getAssociatedObject(base, CuteAttributeKey.rangesKey) as? [NSRange] ?? [defaultRange]
        }
        set {
            objc_setAssociatedObject(base, CuteAttributeKey.rangesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func ranges(_ ranges: [NSRange]) -> CuteAttribute<Base> {
        let isValid = ranges
            .flatMap { return base.string.nsrange >> $0 }
            .reduce(true) { return $0.1 && $0.0 }
        assert(isValid, "ranges must in string.")
        self.ranges = ranges
        return self
    }
}
```
这里使用了runtime添加属性，因为在作用`attributes`的时候需要ranges，要注意额，这里的range方法都做了检查，为了保证添加的range都在改字符串的range之内。
还有这里的每一个方法都返回了`CuteAttribute<Base>`，是为了保证可以链式地调用。

目前`CuteAttribute`还有很多不完善的地方,在接下来我也会将其渐渐完善。  
## TODO：
- 给UITextView、UILabel、UITextField添加扩展，保证其更优雅的使用
- 完善代码中的注释部分
- 添加更多的test  

目前[`CuteAttribute`](https://github.com/qiuncheng/CuteAttribute)已经放在Github上了，不过在添加以上功能之前不会影响主要功能的使用。  

最后 [**Welcome contribution**](https://github.com/qiuncheng/CuteAttribute)