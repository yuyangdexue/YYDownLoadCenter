//
//  YYDownLoadCenter.m
//  Test
//
//  Created by 于洋 on 16/9/8.
//  Copyright © 2016年 于洋. All rights reserved.
//

#import "YYDownLoadCenter.h"
@interface YYDownLoadCenter()
/** 保存所有任务(注：用文件名作为key) */
@property (nonatomic, strong) NSMutableDictionary *tasks;
/** 保存所有下载相关信息 */
@property (nonatomic, strong) NSMutableDictionary *sessionModels;
@end
@implementation YYDownLoadCenter


/**
 *  设置沙盒文件夹路径
 *
 *  @param cachesDirectoryPathComponent 对应的文件夹名
 */
- (void)setCachesDirectoryPathComponent:(NSString *)cachesDirectoryPathComponent
{
    NSString *path = cachesDirectoryPathComponent;
    
    _cachesDirectoryPathComponent = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]  stringByAppendingPathComponent:path];
    
}




- (NSMutableDictionary *)tasks
{
    if (!_tasks) {
        _tasks = [NSMutableDictionary dictionary];
    }
    return _tasks;
}

- (NSMutableDictionary *)sessionModels
{
    if (!_sessionModels) {
        _sessionModels = [NSMutableDictionary dictionary];
    }
    return _sessionModels;
}


static  YYDownLoadCenter *_downloadManager;

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _downloadManager = [super allocWithZone:zone];
    });
    
    return _downloadManager;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    return _downloadManager;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadManager = [[self alloc] init];
    });
    
    return _downloadManager;
}

/**
 *  创建缓存目录文件
 */
- (void)createCacheDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_cachesDirectoryPathComponent]) {
        [fileManager createDirectoryAtPath:_cachesDirectoryPathComponent withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

/**
 *  根据文件名 获取全文件路径
 *
 *  @param fileName  文件名
 *
 *  @return  路径地址
 */
- (NSString *)getFileFullPathByFileName:(NSString *)fileName
{
    return  [_cachesDirectoryPathComponent stringByAppendingPathComponent:fileName];
    
}

/**
 *  获取文件的长度
 *
 *  @param fileName 文件名
 *
 *  @return
 */
- (NSInteger)downloadLength:(NSString *)fileName
{
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:[self  getFileFullPathByFileName:fileName]error:nil][NSFileSize] integerValue];
    
}

/**
 *
 *
 *  @return 存储文件总长度的文件路径（caches）
 */
- (NSString *)totalLengthFullPath
{
    return [_cachesDirectoryPathComponent stringByAppendingPathComponent:@"totalLength.plist"];
}

/**
 *  开启任务下载资源
 */
- (void)download:(NSString *)url  fileName:(NSString *)fileName progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progressBlock state:(void(^)(DownloadState state))stateBlock
{
    if (!url) return;
    if ([self isCompletion:fileName]) {
        stateBlock(DownloadStateCompleted);
        NSLog(@"----该资源已下载完成");
        return;
    }
    
    // 暂停
    if ([self.tasks valueForKey:fileName]) {
        [self handle:url];
        
        return;
    }
    
    // 创建缓存目录文件
    [self createCacheDirectory];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    
    // 创建流
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:[self getFileFullPathByFileName:fileName] append:YES];
    
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    // 设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", [self downloadLength:fileName]];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    // 创建一个Data任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    NSUInteger taskIdentifier = arc4random() % ((arc4random() % 10000 + arc4random() % 10000));
    [task setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
    
    // 保存任务
    [self.tasks setValue:task forKey:fileName];
    
    YYDownLoadModel *sessionModel = [[YYDownLoadModel alloc] init];
    sessionModel.url = fileName;
    sessionModel.progressBlock = progressBlock;
    sessionModel.stateBlock = stateBlock;
    sessionModel.stream = stream;
    [self.sessionModels setValue:sessionModel forKey:@(task.taskIdentifier).stringValue];
    
    [self start:fileName];
}


- (void)handle:(NSString *)fileName
{
    NSURLSessionDataTask *task = [self getTask:fileName];
    if (task.state == NSURLSessionTaskStateRunning) {
        [self pause:fileName];
    } else {
        [self start:fileName];
    }
}

/**
 *  开始下载
 */
- (void)start:(NSString *)fileName
{
    NSURLSessionDataTask *task = [self getTask:fileName];
    if (task) {
        [task resume];
        
        [self getSessionModel:task.taskIdentifier].stateBlock(DownloadStateStart);
    }
    
}

/**
 *  暂停下载
 */
- (void)pause:(NSString *)fileName
{
    NSURLSessionDataTask *task = [self getTask:fileName];
    if (task) {
        [task suspend];
        [self getSessionModel:task.taskIdentifier].stateBlock(DownloadStateSuspended);
    }
    
}

/**
 *  根据url获得对应的下载任务
 */
- (NSURLSessionDataTask *)getTask:(NSString *)fileName
{
    return (NSURLSessionDataTask *)[self.tasks valueForKey:fileName];
}

/**
 *  根据url获取对应的下载信息模型
 */
- (YYDownLoadModel *)getSessionModel:(NSUInteger)taskIdentifier
{
    return (YYDownLoadModel *)[self.sessionModels valueForKey:@(taskIdentifier).stringValue];
}

/**
 *  判断该文件是否下载完成
 */
- (BOOL)isCompletion:(NSString *)fileName
{
    if ([self fileTotalLength:fileName] && [self downloadLength:fileName] == [self fileTotalLength:fileName]) {
        return YES;
    }
    return NO;
}

/**
 *  查询该资源的下载进度值
 */
- (CGFloat)progress:(NSString *)fileName
{
    return [self fileTotalLength:fileName] == 0 ? 0.0 : 1.0 * [self downloadLength:fileName]/  [self fileTotalLength:fileName];
}

/**
 *  获取该资源总大小
 */
- (NSInteger)fileTotalLength:(NSString *)fileName
{
    return [[NSDictionary dictionaryWithContentsOfFile:[self totalLengthFullPath]][fileName] integerValue];
}

#pragma mark - 删除
/**
 *  删除该资源
 */
- (void)deleteFile:(NSString *)fileName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[self getFileFullPathByFileName:fileName]]) {
        
        // 删除沙盒中的资源
        [fileManager removeItemAtPath:[self getFileFullPathByFileName:fileName] error:nil];
        // 删除任务
        [self.tasks removeObjectForKey:fileName];
        [self.sessionModels removeObjectForKey:@([self getTask:fileName].taskIdentifier).stringValue];
        // 删除资源总长度
        if ([fileManager fileExistsAtPath:[self totalLengthFullPath]]) {
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:[self totalLengthFullPath]];
            [dict removeObjectForKey:fileName];
            [dict writeToFile:[self totalLengthFullPath] atomically:YES];
            
        }
    }
}

/**
 *  清空所有下载资源
 */
- (void)deleteAllFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[self totalLengthFullPath]]) {
        // 删除沙盒中所有资源
        [fileManager removeItemAtPath:[self totalLengthFullPath] error:nil];
        // 删除任务
        [[self.tasks allValues] makeObjectsPerformSelector:@selector(cancel)];
        [self.tasks removeAllObjects];
        
        for (YYDownLoadModel *sessionModel in [self.sessionModels allValues]) {
            [sessionModel.stream close];
        }
        [self.sessionModels removeAllObjects];
        
        // 删除资源总长度
        if ([fileManager fileExistsAtPath:[self totalLengthFullPath]]) {
            [fileManager removeItemAtPath:[self totalLengthFullPath] error:nil];
        }
    }
}

#pragma mark - 代理
#pragma mark NSURLSessionDataDelegate
/**
 * 接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    YYDownLoadModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    
    // 打开流
    [sessionModel.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] +  [self downloadLength: sessionModel.url];
    sessionModel.totalLength = totalLength;
    
    // 存储总长度
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:[self totalLengthFullPath]];
    if (dict == nil) dict = [NSMutableDictionary dictionary];
    dict[sessionModel.url] = @(totalLength);
    [dict writeToFile:[self totalLengthFullPath] atomically:YES];
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    YYDownLoadModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    
    // 写入数据
    [sessionModel.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    NSUInteger receivedSize = [self downloadLength:sessionModel.url];
    NSUInteger expectedSize = sessionModel.totalLength;
    CGFloat progress = 1.0 * receivedSize / expectedSize;
    
    sessionModel.progressBlock(receivedSize, expectedSize, progress);
}

/**
 * 请求完毕（成功|失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    YYDownLoadModel *sessionModel = [self getSessionModel:task.taskIdentifier];
    if (!sessionModel) return;
    
    if ([self isCompletion:sessionModel.url]) {
        // 下载完成
        sessionModel.stateBlock(DownloadStateCompleted);
    } else if (error){
        // 下载失败
        sessionModel.stateBlock(DownloadStateFailed);
    }
    
    // 关闭流
    [sessionModel.stream close];
    sessionModel.stream = nil;
    
    // 清除任务
    [self.tasks removeObjectForKey:(sessionModel.url)];
    [self.sessionModels removeObjectForKey:@(task.taskIdentifier).stringValue];
}


@end
