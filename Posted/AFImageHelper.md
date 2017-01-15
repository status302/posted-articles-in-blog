晚上被[AFImageHelper](https://github.com/melvitax/ImageHelper)这个开源库给深深吸引了，早在去年自己刚学习iOS开发时候就做过图片的模糊模板处理，当时用的是UIVisualEffectView处理的，效果很不好。但是今天看到这个库，只想惊叹一声，牛逼了我的哥，基本上把和UIImage相关的扩展都添加了，仔细看了一下代码，不是很难懂，代码量也不是很多，所以阅读起来一定没啥问题，所以我就简单地阅读了一下，主要是想借鉴下别人的实现思路，来补充自己的知识吧。
[![部分实例图](https://raw.githubusercontent.com/melvitax/AFImageHelper/master/Screenshot.png?raw=true)](https://github.com/melvitax/ImageHelper)
#### 从 Image from a URL 说起
```swift
// Fetches an image from a URL. If caching is set, it will be cached by NSCache for future queries. The cached image is returned if available, otherise the placeholder is set. When the image is returned, the closure gets called.
func imageFromURL(url: String, placeholder: UIImage, fadeIn: Bool = true, closure: ((image: UIImage?)
// 参数url: 表示图片url地址
// 参数placeholder: 占位图
// 参数fadeIn: 表示是否以fade形式展示，具体实现用了 CATransition
// 参数clourse: 网络端获取的图片
```
[该方法的具体实现](https://github.com/melvitax/ImageHelper/blob/master/Sources/ImageVIewExtension.swift#L17-L44)。该方法是对`UIImageView`的扩展，该方法主要实现了在有placeholder存在且web image还未加载完成的之前(网络加载需要时间)，先显示placeholder图片，点进去会发现它实际上调用了`UIImage`下面的这个方法：
```Swift
class func image(fromURL url: String, placeholder: UIImage, shouldCacheImage: Bool = true, closure: @escaping (_ image: UIImage?) -> ()) -> UIImage?
```
该类方法是`UIImage`的一个扩展，目的是从网络端获取一张图片，并提供了`placeholder` 和 `cache` 选项，获取的图片放在了 `closure` 里面，返回的图片放在return里面，具体的实现看下面：
```Swift
 class func image(fromURL url: String, placeholder: UIImage, shouldCacheImage: Bool = true, closure: @escaping (_ image: UIImage?) -> ()) -> UIImage? {
        // From Cache
        if shouldCacheImage {
            // 这里可能需要注意下UIImage.shared...
            // 很巧妙的单例设计，不过也有问题
            if let image = UIImage.shared.object(forKey: url as AnyObject) as? UIImage {
                closure(nil)
                return image
            }
        }
        // Fetch Image
        let session = URLSession(configuration: URLSessionConfiguration.default)
        if let nsURL = URL(string: url) {
            session.dataTask(with: nsURL, completionHandler: { (data, response, error) -> Void in
                if (error != nil) {
                    DispatchQueue.main.async {
                        closure(nil)
                    }
                }
                if let data = data, let image = UIImage(data: data) {
                    if shouldCacheImage {
                        UIImage.shared.setObject(image, forKey: url as AnyObject)
                    }
                    DispatchQueue.main.async {
                        closure(image)
                    }
                }
                session.finishTasksAndInvalidate()
            }).resume()
        }
        return placeholder
    }
```
用了 `SDWebImage` 加载 `placeHolder` 图片的方式。将 `placeholder` 放在返回图片里，webImage(异步) 放在闭包里。通过 `UIImageView` 的扩展方法轻松实现 `placeholder` 到 `webImage` 的切换。  
下面是那个巧妙的单例设计，说它巧妙是因为我可能第一次见这种写法，不过也有一定问题，*谁能猜到这个 `UIImage.shared` 实际上是一个 `NSCache` 实例呢？？？不知道为什么这么写。至少我觉得用 `sharedCache` 也比这个好点吧。*
```Swift
 /**
A singleton shared NSURL cache used for images from URL
*/
extension UIImage {
    static var shared: NSCache<AnyObject, AnyObject>! {
        struct StaticSharedCache {
            static var shared: NSCache<AnyObject, AnyObject>? = NSCache()
        }   
        return StaticSharedCache.shared!
    }
}
```
#### 如何实现 `UIImage With Colors`
##### 创建只带一种颜色的 `image` (a solid color)  
1. 创建一个特定 `size` 的 `ImageContext`
2. 获取该`context`
3. 给该`context`指定`fillColor`
4. 获取该`image`
5. 关闭该`context`
```Swift
 convenience init?(color: UIColor, size: CGSize = CGSize(width: 10, height: 10)) {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        self.init(cgImage:(UIGraphicsGetImageFromCurrentImageContext()?.cgImage!)!)
        UIGraphicsEndImageContext()
    }
```
*不过我觉得这个另一种简易可行的方式就是直接设置 `UIView` 的 `backgroundColor` 就OK吧。*
##### 创建一种带梯度的颜色背景图片 (a gradient color)
设置方式代码和上面设置 `a solid color` 一样，只不过多了一条`context.drawLinearGradient` 设置。
```Swift
 convenience init?(gradientColors:[UIColor], size:CGSize = CGSize(width: 10, height: 10), locations: [Float] = [] )
    {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = gradientColors.map {(color: UIColor) -> AnyObject! in return color.cgColor as AnyObject! } as NSArray
        let gradient: CGGradient
        if locations.count > 0 {
          // 在这里使用map做了转换，将 Float 转换成 CGFloat
          let cgLocations = locations.map { CGFloat($0) }
          gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: cgLocations)!
        } else {
          gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
        }
        context!.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: CGGradientDrawingOptions(rawValue: 0))
        self.init(cgImage:(UIGraphicsGetImageFromCurrentImageContext()?.cgImage!)!)
        UIGraphicsEndImageContext()
    }
```
##### 给已有图片添加一层梯度模板 (Applies gradient color overlay to an image.)
这个和上面的`a gradient color`实现方式很像，上面那条只是创建一个梯度模板的图片，而这里给已有图片添加梯度模板，所以这里相比于上面那个实现就多了将context绘制在image上步骤，当然别忘了clip操作，不然获取的图片大小size可能不和原来一样。[该段代码的具体实现在这里](https://github.com/melvitax/ImageHelper/blob/master/Sources/ImageHelper.swift#L84-L119)，为了节省篇幅就不将代码贴出来了。  
*不过我还是觉得原作者这么写是不严密的，原因如下：*  
*self.cgImage可能返回NULL的情况，具体情况请看官方文档 [If the UIImage object was initialized using a CIImage object, the value of the property is NULL.](https://developer.apple.com/reference/uikit/uiimage/1624147-cgimage), 这个时候就没必要进行下面的操作了。*
##### 创建一个带Label的图片(Creates a text label image.)
这个实现还是比较好理解的，步骤如下：[具体实现在这里](https://github.com/melvitax/ImageHelper/blob/master/Sources/ImageHelper.swift#L121-L164)  
1. 创建一个UILabel
2. 将UILabel转换成UIImage
3. 将UIImage以convenience形式初始化出来  

可能难点在于步骤2, 具体实现如下:
```Swift
    convenience init?(fromView view: UIView) {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!) // 将view的layer绘制在imageContext上
        self.init(cgImage:(UIGraphicsGetImageFromCurrentImageContext()?.cgImage!)!)
        UIGraphicsEndImageContext()
    }
```
##### 创建放射状的 UIImage (Image with Radial Gradient)
一开始我以为实现这个是很难的，但是在看完该代码之后，瞬间觉得很简单，直接使用UIGraphicsGetCurrentContext()?.drawRadialGradient(...)方法完美解决。该方法参数比较多，不过都是那种我们一下子就能看懂意思的，在这里就不细说了，[具体实现在这里](https://github.com/melvitax/ImageHelper/blob/master/Sources/ImageHelper.swift#L166-L203)，实现步骤如下：    
1. 初始化`drawRadialGradient`方法需要的参数，    
`这里需要注意创建 CGGradient 的时候使用 public init?(colorSpace space: CGColorSpace, colorComponents components: UnsafePointer<CGFloat>, locations: UnsafePointer<CGFloat>?, count: Int) 这个初始化方法。`  
2. 实行绘制操作
##### 检测图片是否包含`Alpha`
实现如下：
```Swift
 var hasAlpha: Bool {
    let alpha: CGImageAlphaInfo = self.cgImage!.alphaInfo
    switch alpha {
    case .first, .last, .premultipliedFirst,    .premultipliedLast:
        return true
    default:
        return false
    }
}    
```
至于CGImageAlphaInfo，贴张图：根据这个很容易就知道为什么作者在这里使用了  
`case .first, .last, .premultipliedFirst`
![](http://7xk67j.com1.z0.glb.clouddn.com/CGImageAlphaInfo.jpg)
