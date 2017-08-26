大多数使用`SDWebImage`的APP，都是在直接使用`sd_setImageWithURL:`系列方法。而且我们在使用SDWebImage的时候，大多数情况下只需要导入`#import "UIImageView+WebCache.h"`就OK啦，所以在分析SDWebImage这个开源库的开头，我打算以`sd_setImageWithURL:`开始。
### sd_setImageWithURL具体是什么
以前在使用SD的时候，其实并没有注意，原来作者帮我们提供了**7**种`sd_setImageWithURL:`便利方法。在这7中便利方法中,有三种是不包含`completion`回调的,有四种是包含`completion`回调的.今天我们先不谈这些便利方法的使用,毕竟就是一两行代码的事情。不过点击方法进去就可以看到所有的方法都调用了一个方法，这个方法就如下图所示：
![](https://github.com/qiuncheng/posted-articles-in-blog/blob/master/images/sd_setImageWithURL.jpeg?raw=true)
由此也可以看出来，SD的设计还是很简洁的，在UIImageView分类方面，一个方法，也可以说是一行代码，就解决了Web图片的展示问题。
### 这个方法内部做了哪些事情：
如果我们不去看源码的话，依据我们现有的iOS开发相关的知识来分析，也可以分析个一二出来：这个方法肯定去下载了图片，可能还有图片的缓存，以及图片`placeholder`的显示等。  
那么这个方法内部究竟是什么样的呢？
```
///第一行代码
[self sd_cancelCurrentImageLoad];
```
这个方式实际上只做了一件事情，cancel掉当前正在进行的下载的操作。不过有趣的是，与该方法有关的操作却很巧妙地放在`UIView`上,因为不仅仅只有UIImageView下载图片,UIButton也包含了下载图片的操作.所以放在他两的父类上，更加方便管理，直接cancel，不会影响接下来的下载操作。
#### placeholder的实现
```
if (!(options & SDWebImageDelayPlaceholder)) {
        dispatch_main_async_safe(^{
            self.image = placeholder;
        });
    }
```
从上面的代码中也可以看出来，placeholder无非也是使用了一个临时的图片（placeholder）这个临时的图片是我们外部传进来的。如果我们没有设置，那么默认就是`nil`,反正在`Objective-C`下`self.image`属性默认就是`nil`, 无伤大雅。
#### 图片的下载操作
![](https://github.com/qiuncheng/posted-articles-in-blog/blob/master/images/sd_setImageWithURL2.png?raw=true)
SD在获取图片时先检测URL，在不为nil的情况下，再去执行下载操作，否则就会报错。在上图中我们还可以明显看到，下载图片的操作是由`SDWebImageManager`来操作的, 下载完成`completed`闭包回调。尤其需要关注这一句代码`[self sd_setImageLoadOperation:operation forKey:@"UIImageViewImageLoad"];`这个方法背后是将`operation`加入到字典`operationDictionary`中, 通过键值的方式，我们可以很方便地取消该operation操作。我们先不去关注具体的下载过程，先去看下下载完成后的操作有哪些。
![](https://github.com/qiuncheng/posted-articles-in-blog/blob/master/images/sd_setImageWithURL3.png?raw=true)
从上图可以看到，该完成回调闭包主要是将图片显示出来，如果你使用了`SDWebImageAvoidAutoSetImage`模式, 那么图片就不会显示出来, 如果图片没有获取到，而且使用了`SDWebImageDelayPlaceholder`模式, 那么就显示placeholder，在这里可以关注下它的判断条件，主要还是围绕`SDWebImageOptions`和`image`来看, 应该都不难理解。
#### 图片下载过程的activity实现
在使用SD的时候，我们可以指定是否显示`ActivityIndicatorView`, 代码示意如下, 第一行代码设置是否显示`ActivityIndicatorView`, 第二行代码设置该`ActivityIndicatorView`样式。但是在`Objective-C`大环境下，给`extension`添加一个属性，不难，但是却是比较繁琐的，通过`runtime`的`objc_setXXX`, 和`objc_getXXX`来实现。
```
[self.imageView setShowActivityIndicatorView:YES];
[self.imageView setIndicatorStyle:UIActivityIndicatorViewStyleGray];
```
其实`[self.imageView setShowActivityIndicatorView:YES];`代码只是将key为`TAG_ACTIVITY_SHOW`的属性标记为`YES`状态, 然后在下载图片时候，根据key为`TAG_ACTIVITY_SHOW`的属性来决定是否显示`ActivityIndicatorView`。第二行代码主要实现设置`ActivityIndicatorView`的样式，也和设置显示与否一样，就不具体分析了。那么如何将`ActivityIndicatorView`添加UIImageView上呢？下图可以很清楚地描述，那段比较长的代码主要是添加约束，我们可以不去care它，还可以看到添加了`ActivityIndicatorView`就立马`startAnimation`了。
```
- (void)addActivityIndicator {
    if (!self.activityIndicator) {
        /// [self getIndicatorStyle]获取的属性是我们自己获取的，默认是0，也就是 UIActivityIndicatorViewStyleWhiteLarge 样式的
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[self getIndicatorStyle]];
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;

        dispatch_main_async_safe(^{
            [self addSubview:self.activityIndicator];
            /// 添加约束代码，已省略
        });
    }
    dispatch_main_async_safe(^{
        [self.activityIndicator startAnimating]; /// 添加上了立马开启动画
    });
}
```
### 与这个方法有关的有哪些
#### sd_setImageWithPreviousCachedImageWithURL
方法内部代码：
```
NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
UIImage *lastPreviousCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:key];
[self sd_setImageWithURL:url placeholderImage:lastPreviousCachedImage ?: placeholder options:options progress:progressBlock completed:completedBlock];    
```
该方法我们只需要关注一个点，那就是`imageFromDiskCacheForKey`, 我们不用仔细查看代码的话也可以知道, 这是从硬盘缓存中获取图片, 对应的key由该URL组合而成, 然后将从硬盘里面获取的作为placeholder再次使用sd_setImageWithURL方法, 去获取图片。也就是说，使用了该方法之后，优先去加载缓存中的图片的，然后再去加载网络获取的图片，其实使用这种方式更加切合实际的开发。如果有缓存，那么placeholder就显示缓存中的图片，如果没有缓存，那么就显示我们设置的placeholder，然后再去下载图片。**推荐大家都使用这个方法**
#### sd_setAnimationImagesWithURLs
设置动画图片组，参数是一个url数组。这个方法里面只有一个参数，内部还是使用了`SDWebImageManager`去下载图片, 依次遍历url数组里面的url，去下载每一张图片，将下载好的放入UIImageView的animationImages中，并在每一次下载完成后都开启动画。其实这里有一个问题，那就是SD是如何保证下载的这些图片的顺序的？假如有1、2、3、4张图片，那么如果保证animationImages数组中图片的顺序是1、2、3、4呢？这个问题我们将在下一系列探讨一下。
### 简单总结
本文主要是简要分析了一下`SDWebImage`中`UIImageView+WebCache.h`中的方法等，主要还是这个`sd_setImageWithURL`方法。  
作为笔者分析SDWebImage的第一篇文章, 本文略显简单, SDWebImage的核心东西一点都没有涉及。不过我将会在后面的文章中一一分析。接下来的模块系列有：
- SDWebImage的图片缓存
- SDWebImage的图片下载
- SDWebImage的图片处理等