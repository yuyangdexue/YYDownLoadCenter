//
//  YYDownLoadCenter.h
//  Test
//
//  Created by 于洋 on 16/9/8.
//  Copyright © 2016年 于洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYDownLoadModel.h"

#define GlobalDownLoadCenter [YYDownLoadCenter sharedInstance]

@interface YYDownLoadCenter : NSObject
/**
 *   已经把把文件缓存到cache （防止APPSTORE 被拒绝）目录下 后面拼接 文件路径 需要设置沙盒路径
 */
@property (nonatomic, strong)  NSString *cachesDirectoryPathComponent;

/**
 *  单例
 *
 *  @return 返回单例对象
 */
+ (instancetype)sharedInstance;

/**
 *  开启任务下载资源
 *
 *  @param url           下载地址
 *  @param fileName   文件名字
 *  @param progressBlock 回调下载进度
 *  @param stateBlock    下载状态
 */
- (void)download:(NSString *)url  fileName:(NSString *)fileName progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progressBlock state:(void(^)(DownloadState state))stateBlock;

/**
 *  查询该资源的下载进度值
 *
 *  @param fileName 文件名
 *
 *  @return 返回下载进度值
 */
- (CGFloat)progress:(NSString *)fileName;

/**
 *  获取该资源总大小
 *
 *  @param fileName 文件名
 *
 *  @return 资源总大小
 */
- (NSInteger)fileTotalLength:(NSString *)fileName;

/**
 *  判断该资源是否下载完成
 *
 *  @param fileName 文件名
 *
 *  @return YES: 完成
 */
- (BOOL)isCompletion:(NSString *)fileName;

/**
 *  删除该资源
 *
 *  @param fileName 文件名
 */
- (void)deleteFile:(NSString *)fileName;

/**
 *  清空所有下载资源
 */
- (void)deleteAllFile;

@end
