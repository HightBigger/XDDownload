//
//  NSString+XDExtension.m
//  downloadDemo
//
//  Created by xiaoda on 2018/8/27.
//  Copyright © 2018年 nationsky. All rights reserved.
//

#import "NSString+XDExtension.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (XDExtension)

- (NSString *)md5
{
    const char* str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:33];
    
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02X",result[i]];
    }
    return ret;
    
}


@end
