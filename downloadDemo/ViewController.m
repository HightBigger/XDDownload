//
//  ViewController.m
//  downloadDemo
//
//  Created by xiaoda on 2018/8/27.
//  Copyright © 2018年 nationsky. All rights reserved.
//

#import "ViewController.h"
#import "XDDownloadManager.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) NSMutableArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"下载管理";
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;    
}

#pragma mark -action
- (void)downloadOneFile
{
    NSString *QQfile = @"https://sm.myapp.com/original/im/QQ9.0.4-9.0.4.23780.exe";
    
    [[XDDownloadManager shareIntance] downloadFileWithURL:[NSURL URLWithString:QQfile]];
}

- (void)downloadMultiFiles
{
    NSArray *files = @[@"https://sm.myapp.com/original/Browser/67.0.3396.99_chrome_installer.exe",
                       @"https://sm.myapp.com/original/Input/sogou_pinyin_9.0.0.2388_6990.exe",
                       @"https://sm.myapp.com/original/Video/QQliveSetup_20_523-10.9.2173.0.exe"];
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
    
    for (NSString *str in files)
    {
        NSURL *url = [NSURL URLWithString:str];
        
        [array addObject:url];
    }
    
    [[XDDownloadManager shareIntance] downloadMultiFilesWithURLArray:array];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    
    cell.textLabel.text = self.dataArray[indexPath.row];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0)
    {
        [self downloadOneFile];
    }
    else if(indexPath.row == 1)
    {
        [self downloadMultiFiles];
    }
}

#pragma mark - lazyload

- (NSMutableArray *)dataArray
{
    if (!_dataArray)
    {
        _dataArray = [NSMutableArray arrayWithCapacity:0];
        
        [_dataArray addObject:@"下载单个文件"];
        [_dataArray addObject:@"批量下载文件"];
        
    }
    return _dataArray;
}


@end
