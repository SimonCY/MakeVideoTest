//
//  Cell.m
//  集合视图-UICollectionView
//
//  Created by imac on 15/9/20.
//  Copyright (c) 2015年 neusoft. All rights reserved.
//

#import "Cell.h"

@implementation Cell

-(instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, self.frame.size.width-10, self.frame.size.width-10)];
        [self addSubview:self.imageView];
        self.imageView.backgroundColor = [UIColor whiteColor];
        
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(5, self.frame.size.height - 20, self.frame.size.width-10, 20)];
        self.label.font = [UIFont systemFontOfSize:10];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textAlignment = NSTextAlignmentRight;
        [self addSubview:self.label];
        
        
        self.layer.shadowOffset = CGSizeMake(3, 3);
        self.layer.shadowOpacity = 0.8;
        self.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    }
    return self;
}

@end
