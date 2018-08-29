//
//  XDTableViewCell.m
//  downloadDemo
//
//  Created by xiaoda on 2018/8/27.
//  Copyright © 2018年 nationsky. All rights reserved.
//

#import "XDTableViewCell.h"

#define cellH 80

@interface XDTableViewCell()

@property (nonatomic,strong) UIView *line;

@end

@implementation XDTableViewCell

+ (CGFloat)cellHeight
{
    return cellH;
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self.contentView addSubview:self.titleLab];
    [self.contentView addSubview:self.line];
}

#pragma mark - lazyload
- (UILabel *)titleLab
{
    if (!_titleLab)
    {
        _titleLab = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 150, cellH)];
        _titleLab.font = [UIFont systemFontOfSize:17];
        _titleLab.textColor = [UIColor blackColor];
    }
    return _titleLab;
}

- (UIView *)line
{
    if (!_line)
    {
        _line = [[UIView alloc]initWithFrame:CGRectMake(0, cellH-1, [UIScreen mainScreen].bounds.size.width, 0.5)];
        _line.backgroundColor = [UIColor lightGrayColor];
    }
    return _line;
}

@end
