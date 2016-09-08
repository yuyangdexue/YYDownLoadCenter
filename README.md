# YYDownLoadCenter


[![CI Status](http://img.shields.io/travis/yuyang/YYDownLoadCenter.svg?style=flat)](https://travis-ci.org/yuyang/YYDownLoadCenter)
[![Version](https://img.shields.io/cocoapods/v/YYDownLoadCenter.svg?style=flat)](http://cocoapods.org/pods/YYDownLoadCenter)
[![License](https://img.shields.io/cocoapods/l/YYDownLoadCenter.svg?style=flat)](http://cocoapods.org/pods/YYDownLoadCenter)
[![Platform](https://img.shields.io/cocoapods/p/YYDownLoadCenter.svg?style=flat)](http://cocoapods.org/pods/YYDownLoadCenter)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

YYDownLoadCenter is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "YYDownLoadCenter"
```

## Author

yuyang, 15246071818@163.com

## License

YYDownLoadCenter is available under the MIT license. See the LICENSE file for more info.

参考 https://github.com/HHuiHao/HSDownloadManager 
当服务器url 是加密的字段的时候，没有固定的问题 通过传文件名来控制下载任务以及断点续传

使用方法 
GlobalDownLoadCenter.cachesDirectoryPathComponent =  "book/bookid";
[GlobalDownLoadCenter download:url fileName:fileName progress:^(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress) {
        
 } state:^(DownloadState state) {
        
 }];

