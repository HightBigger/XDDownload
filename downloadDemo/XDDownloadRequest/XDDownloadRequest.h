//
//  XDDownloadRequest.h
//  AppNest
//
//  Created by xiaoda on 2018/2/6.
//  Copyright © 2018年 NationSky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+XDExtension.h"

@interface XDDownloadRequest : NSObject


/**
 下载文件请求(在不考虑同时下载相同文件时使用)
 
 @param requestURL 下载地址
 @param localPath 下载完成文件夹
 @return NSURLSessionDataTask
 */

- (NSURLSessionDataTask *)downloadFileWithUrl:(NSURL *)requestURL
                                    localPath:(NSString *)localPath
                                    httpHeader:(NSDictionary*)httpHeader
                             receiveDataBlock:(void (^)(NSURLSessionDataTask *sessionDataTask, NSProgress *progress, NSData *data ,NSString *tempFile,NSString *FileName))receiveDataBlock
                            completionHandler:(void (^)(NSURLSessionDataTask *sessionDataTask, NSString *filePath, NSError *error,NSString *FileName))completionHandler;

/**
 下载文件请求(考虑有同文件，同时下载时使用这个方法)
 
 @param requestURL 下载地址
 @param tempPath 缓存地址
 @param localPath 下载完成文件夹
 @return NSURLSessionDataTask
 */

- (NSURLSessionDataTask *)downloadFileWithUrl:(NSURL *)requestURL
                                    tempPath:(NSString *)tempPath
                                    localPath:(NSString *)localPath
           receiveDataBlock:(void (^)(NSURLSessionDataTask *sessionDataTask, NSProgress *progress, NSData *data ,NSString *tempFile,NSString *FileName))receiveDataBlock
          completionHandler:(void (^)(NSURLSessionDataTask *sessionDataTask, NSString *filePath, NSError *error,NSString *FileName))completionHandler;


- (NSString *)getDownloadingFilePath:(NSString *)downloadurl;

@end
