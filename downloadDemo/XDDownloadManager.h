//
//  XDDownloadManager.h
//  downloadDemo
//
//  Created by xiaoda on 2018/8/27.
//  Copyright © 2018年 nationsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XDDownloadManager : NSObject

+ (XDDownloadManager *)shareIntance;

- (void)downloadFileWithURL:(NSURL *)url;

- (void)downloadMultiFilesWithURLArray:(NSArray *)urlArray;

@end
