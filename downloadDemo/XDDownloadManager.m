//
//  XDDownloadManager.m
//  downloadDemo
//
//  Created by xiaoda on 2018/8/27.
//  Copyright © 2018年 nationsky. All rights reserved.
//

#import "XDDownloadManager.h"
#import "XDDownloadRequest.h"

@implementation XDDownloadManager
{
    XDDownloadRequest* request;
    NSMutableArray* downloadingArray;
}

+ (XDDownloadManager *)shareIntance
{
    static XDDownloadManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[XDDownloadManager alloc]init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        request = [[XDDownloadRequest alloc]init];
        
        downloadingArray = [NSMutableArray arrayWithCapacity:0];
        
        
        
    }
    return self;
}

- (void)downloadFileWithURL:(NSURL *)url
{
    NSDictionary *dic = [self getDownloadDic:url.absoluteString];
    
    NSString *tempFile = @"";
    if (dic)
    {
        tempFile = [dic objectForKey:@"tempFile"];
    }
    else
    {
        tempFile = [request getDownloadingFilePath:url.absoluteString];
    }
    
    __weak typeof(self) weakSelf = self;
    
    [request downloadFileWithUrl:url tempPath:tempFile localPath:[self getFilepath] receiveDataBlock:^(NSURLSessionDataTask *sessionDataTask, NSProgress *progress, NSData *data, NSString *tempFile,NSString *FileName) {
        
        [weakSelf saveDownLoadingFileUrl:url.absoluteString tempFile:tempFile];
        
        NSLog(@"%@正在下载:%.2f",FileName,progress.fractionCompleted);
        
        
    } completionHandler:^(NSURLSessionDataTask *sessionDataTask, NSString *filePath, NSError *error,NSString *FileName) {
        
        
        [weakSelf removeDownloadingFileUrl:url.absoluteString];
        
        if (!error)
        {
            NSLog(@"%@下载完成",FileName);
        }
        else
        {
            NSLog(@"%@下载失败",FileName);
        }
    }];
}


- (void)downloadMultiFilesWithURLArray:(NSArray *)urlArray
{
    for (NSURL *url in urlArray)
    {
        [self downloadFileWithURL:url];
    }
}

- (void)saveDownLoadingFileUrl:(NSString *)url
                      tempFile:(NSString *)tempFile
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *dic = @{
                          @"isDownloading":@YES,
                          @"tempFile":tempFile
                          };
    [userDefaults setObject:dic forKey:url];
    
}


- (void)removeDownloadingFileUrl:(NSString *)url
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:url];
}

- (NSDictionary *)getDownloadDic:(NSString *)url
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *dic = [userDefaults objectForKey:url];
    
    return dic;
}

- (NSString *)getFilepath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *fileDirectory = [paths[0] stringByAppendingPathComponent:@"downloaded"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileDirectory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    return fileDirectory;
}

@end
