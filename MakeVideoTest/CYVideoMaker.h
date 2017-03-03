//
//  CYVideoToolBox.h
//  MakeVideoTest
//
//  Created by RRTY on 17/2/24.
//  Copyright © 2017年 deepAI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CYSingleton.h"

@interface CYVideoMaker : NSObject
CYSingletonH(CYVideoMaker)

//videoSize   default is 360 * 360
@property (nonatomic,assign) CGSize targetSize;
//default is 10      it means show  a  frame  per 0.1s
@property (nonatomic,assign) CGFloat timeScale;

- (void)compressedMovieWithImages:(NSArray *)images completionHandlerOnMainThread:(void (^)(NSString *videoPath))handler;
@end
