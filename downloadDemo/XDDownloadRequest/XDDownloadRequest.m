//
//  XDDownloadRequest.m
//  AppNest
//
//  Created by xiaoda on 2018/2/6.
//  Copyright © 2018年 NatioXD. All rights reserved.
//

#import "XDDownloadRequest.h"

@class XDDownloadRequestDelegate;

typedef void (^XDReceiveDataBlock)(NSURLSessionDataTask *sessionTask,NSProgress *progress,NSData *data,NSString *tempFile,NSString *fileName);
typedef void (^XDCompletionHandler)(NSURLSessionDataTask *sessionTask,NSString *filePath,NSError *error,NSString *fileName);

@interface XDDownloadRequest_Listener : NSObject

@property(nonatomic,strong) NSURLSessionDataTask *sessionTask;
@property(nonatomic,strong) NSString *tempPath;
@property(nonatomic,strong) NSString *localPath;
@property(nonatomic,strong) NSString *fileName;
@property(nonatomic,strong) NSString *downloadUrl;
@property(nonatomic,assign) int64_t totalSize;
@property(nonatomic,assign) int64_t downloadSize;
@property(nonatomic,strong) NSProgress *progress;
@property(nonatomic,strong) NSError *error;

@property(nonatomic,copy)   XDReceiveDataBlock receiveDataBlock;
@property(nonatomic,copy)   XDCompletionHandler completionHandler;

@end

@implementation XDDownloadRequest_Listener

@end


@interface XDDownloadRequest ()<NSURLSessionDataDelegate>
@property (nonatomic , strong) NSMutableArray<XDDownloadRequest_Listener*> *listenerArray;
@property (nonatomic,strong) NSLock* lock;
@end


@implementation XDDownloadRequest

- (id)init
{
    self = [super init];
    if (self)
    {
        _listenerArray = [NSMutableArray arrayWithCapacity:0];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (NSURLSessionDataTask *)downloadFileWithUrl:(NSURL *)requestURL
                                    localPath:(NSString *)localPath
                                    httpHeader:(NSDictionary*)httpHeader
                             receiveDataBlock:(void (^)(NSURLSessionDataTask *, NSProgress *, NSData * ,NSString *,NSString *))receiveDataBlock
                            completionHandler:(void (^)(NSURLSessionDataTask *, NSString *, NSError *,NSString *))completionHandler
{
    NSString *tempPath = [self getDownloadingFilePath:requestURL.absoluteString];
    
    //取出本地缓存文件
    uint64_t size = [self fileSizeForPath:tempPath];
    //添加range,从某个字节开始下载
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:requestURL];
    if (size > 0)
    {
        NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", size];
        [request setValue:requestRange forHTTPHeaderField:@"Range"];
    }
    
    if (httpHeader != nil)
    {
        [httpHeader enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj)
                [request setValue:obj forHTTPHeaderField:key]; 
        }];
    }
    
    
    XDDownloadRequest_Listener *listener = [[XDDownloadRequest_Listener alloc]init];
    listener.tempPath = tempPath;
    listener.localPath = localPath;
    listener.receiveDataBlock = receiveDataBlock;
    listener.completionHandler = completionHandler;
    listener.downloadUrl = requestURL.absoluteString;
    listener.downloadSize = size;//需要判断缓存文件
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    listener.sessionTask = [session dataTaskWithRequest:request];
    [listener.sessionTask resume];
    
    [_lock lock];
    [_listenerArray addObject:listener];
    [_lock unlock];
    
    return listener.sessionTask;
}

- (NSURLSessionDataTask *)downloadFileWithUrl:(NSURL *)requestURL
                                     tempPath:(NSString *)tempPath
                                    localPath:(NSString *)localPath
           receiveDataBlock:(void (^)(NSURLSessionDataTask *, NSProgress *, NSData * ,NSString *,NSString *))receiveDataBlock
          completionHandler:(void (^)(NSURLSessionDataTask *, NSString *, NSError *,NSString *))completionHandler
{
    //取出本地缓存文件
    int64_t size = [self fileSizeForPath:tempPath];
    //添加range,从某个字节开始下载
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:requestURL];
    if (size > 0)
    {
        NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", size];
        [request setValue:requestRange forHTTPHeaderField:@"Range"];
    }
    
    XDDownloadRequest_Listener *listener = [[XDDownloadRequest_Listener alloc]init];
    listener.tempPath = tempPath;
    listener.localPath = localPath;
    listener.receiveDataBlock = receiveDataBlock;
    listener.completionHandler = completionHandler;
    listener.downloadUrl = requestURL.absoluteString;
    listener.downloadSize = size;//需要判断缓存文件
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    listener.sessionTask = [session dataTaskWithRequest:request];
    [listener.sessionTask resume];
    [_lock lock];
    [_listenerArray addObject:listener];
    [_lock unlock];
    return listener.sessionTask;
}

-(XDDownloadRequest_Listener*)findListenserByTask:(NSURLSessionTask *)dataTask
{
    XDDownloadRequest_Listener* listenser = nil;
    [_lock lock];
    for (int i = 0; i < _listenerArray.count; i++)
    {
        XDDownloadRequest_Listener* li = [_listenerArray objectAtIndex:i];
        if (li.sessionTask == dataTask)
        {
            listenser = li;
            break;
        }
    }
    [_lock unlock];
    return listenser;
}

//NSURLSessionDataTask 代理
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{

    XDDownloadRequest_Listener* listenser = [self findListenserByTask:dataTask];
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSInteger statusCode = [httpResponse statusCode];
    if (statusCode >= 400)
    {
        [[NSFileManager defaultManager]removeItemAtPath:listenser.tempPath error:nil];
        NSError *error = [NSError errorWithDomain:@"downloadRequest.error" code:statusCode userInfo:@{NSLocalizedDescriptionKey : @"文件不存在"}];
        listenser.error = error;
        completionHandler(NSURLSessionResponseAllow);
    }
    else
    {
        NSDictionary *res = [httpResponse allHeaderFields];
        NSString *fileName = [response suggestedFilename];//下载包名 wcdb-master.zip
        const char *byte = [fileName cStringUsingEncoding:NSISOLatin1StringEncoding];
        fileName = [[NSString alloc] initWithCString:byte encoding: NSUTF8StringEncoding];
        NSString *contentLength = [res objectForKey:@"Content-Length"];//文件总长度
        listenser.totalSize = [contentLength longLongValue] + [self fileSizeForPath:listenser.tempPath];
        fileName = [fileName stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        fileName = [fileName stringByRemovingPercentEncoding];
        listenser.fileName = fileName;
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    XDDownloadRequest_Listener* listenser = [self findListenserByTask:dataTask];
    if (listenser.error != nil && listenser.error.code>=400) return;
    //写入文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:listenser.tempPath])
    {
        NSFileHandle *handleFile = [NSFileHandle fileHandleForUpdatingAtPath:listenser.tempPath];
        [handleFile seekToEndOfFile];
        [handleFile writeData:data];
        [handleFile closeFile];
    }
    else
    {
        listenser.tempPath = [self getDownloadingFilePath:listenser.downloadUrl];
        [data writeToFile:listenser.tempPath atomically:YES];
    }
    
    listenser.downloadSize += data.length;
    if (!listenser.progress)
    {
        listenser.progress = [NSProgress progressWithTotalUnitCount:listenser.totalSize];
    }
    listenser.progress.completedUnitCount = listenser.downloadSize;
    
    NSArray *tempArray = [listenser.tempPath componentsSeparatedByString:@"/"];
    NSString *tempFile = [tempArray lastObject];
    
    if (listenser.receiveDataBlock)
    {
        listenser.receiveDataBlock(dataTask, listenser.progress, data,tempFile,listenser.fileName);
    }
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    // 1.判断服务器返回的证书类型, 是否是服务器信任
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {   
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential , card);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)dataTask didCompleteWithError:(nullable NSError *)error
{
    XDDownloadRequest_Listener* listenser = [self findListenserByTask:dataTask];
    NSString *homepath = listenser.localPath;
    listenser.localPath = [listenser.localPath stringByAppendingPathComponent:listenser.fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:listenser.localPath])
    {
        int i = 0;
        //若已存在相同文件，则添加后缀
        while ([[NSFileManager defaultManager] fileExistsAtPath:listenser.localPath])
        {
            i++;
            listenser.localPath = [NSString stringWithFormat:@"%@/%@(%d).%@",homepath,[listenser.fileName stringByDeletingPathExtension],i,[listenser.fileName pathExtension]];
        }
    }
    
    if (!error && listenser.tempPath && !listenser.error)
    {
        [[NSFileManager defaultManager] moveItemAtPath:listenser.tempPath toPath:listenser.localPath error:nil];
    }
    //404的情况是，error为空 listenser.error 不为空
    NSError *backError = error ? error : listenser.error;
    if (listenser.completionHandler)
    {
        listenser.completionHandler(listenser.sessionTask, listenser.localPath, backError,listenser.fileName);
    }
    
    //将完成的下载任务移除
    [_lock lock];
    [_listenerArray removeObject:listenser];
    [_lock unlock];
}

//根据下载地址获取缓存地址
- (NSString *)getDownloadingFilePath:(NSString *)downloadurl
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *fileDirectory = [paths[0] stringByAppendingPathComponent:@"downloadcache"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    //缓存文件名为下载地址的MD5值
    NSString *filepath = [NSString stringWithFormat:@"%@/%@",fileDirectory,downloadurl.md5];
    
    int i = 0;
    while ([[NSFileManager defaultManager] fileExistsAtPath:filepath])
    {
        i++;
        filepath = [NSString stringWithFormat:@"%@/%@(%d)",fileDirectory,downloadurl.md5,i];
    }
    
    return filepath;
}

//计算文件大小
- (int64_t)fileSizeForPath:(NSString *)path
{
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path])
    {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict)
        {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}

@end
