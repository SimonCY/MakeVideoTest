//
//  CYVideoToolBox.m
//  MakeVideoTest
//
//  Created by RRTY on 17/2/24.
//  Copyright © 2017年 deepAI. All rights reserved.
//

#import "CYVideoMaker.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation CYVideoMaker

CYSingletonM(CYVideoMaker)


- (instancetype)init {
    if (self = [super init]) {
        self.targetSize = CGSizeMake(360, 360);
        self.timeScale = 10;
    }
    return self;
}



- (NSString *)newMoviePath {
    
    //生成时间戳
    long recordTime = (NSInteger)[[NSDate date] timeIntervalSince1970]*1000;
    NSString *timeString = [NSString stringWithFormat:@"%ld",recordTime];
    NSLog(@"timeString is %@",timeString);
    
    //生成路径
    NSArray *CachesPaths =NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    NSString *moviePath =[[CachesPaths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",timeString]];
    return moviePath;
}


-(void)compressedMovieWithImages:(NSArray *)images completionHandlerOnMainThread:(void (^)(NSString *))handler {
    NSAssert(images.count, @"源图片数组为空");
    
    NSLog(@"开始合成");
    //NSString *moviePath = [[NSBundle mainBundle]pathForResource:@"Movie" ofType:@"mov"];
    NSString *moviePath = [self newMoviePath];
    

    
    //    [selfwriteImages:imageArr ToMovieAtPath:moviePath withSize:sizeinDuration:4 byFPS:30];//第2中方法
    
    NSError *error =nil;
    
    NSLog(@"moviePath is ->%@",moviePath);
    unlink([moviePath UTF8String]);
    NSLog(@"unlink 之后  moviePath is ->%@",moviePath);
    
    //—-initialize compression engine
    AVAssetWriter *videoWriter =[[AVAssetWriter alloc]initWithURL:[NSURL fileURLWithPath:moviePath] fileType:AVFileTypeMPEG4 error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings =[NSDictionary dictionaryWithObjectsAndKeys:
                                      AVVideoCodecH264,AVVideoCodecKey,
                                      [NSNumber numberWithInt:self.targetSize.width],AVVideoWidthKey,
                                      [NSNumber numberWithInt:self.targetSize.height],AVVideoHeightKey,nil];
    
    AVAssetWriterInput *writerInput =[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];

    NSDictionary *sourcePixelBufferAttributesDictionary =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey,nil];
        
        AVAssetWriterInputPixelBufferAdaptor *adaptor =[AVAssetWriterInputPixelBufferAdaptor
                                                        assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                        sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    if (![videoWriter canAddInput:writerInput]) return;

    [videoWriter addInput:writerInput];
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //合成多张图片为一个视频文件
    dispatch_queue_t dispatchQueue =dispatch_queue_create("mediaInputQueue",NULL);
    int __block frame = 0;
    
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while([writerInput isReadyForMoreMediaData]) {
            if(++frame >= images.count * 1) {
                [writerInput markAsFinished];

                [videoWriter finishWritingWithCompletionHandler:^{
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (handler) {
                            handler(moviePath);
                        }
                    });
                }];
                break;
            }
            
            CVPixelBufferRef buffer =NULL;
            
            int idx =frame/1;
            NSLog(@"idx==%d",idx);
            
            buffer =(CVPixelBufferRef)[self pixelBufferFromCGImage:[[images objectAtIndex:idx] CGImage] size:self.targetSize];
            
            if (buffer) {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame,self.timeScale)]) {
                    NSLog(@"FAIL");
                } else {
                    NSLog(@"OK");
                    CFRelease(buffer);
                }
            }
        }
    }];
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options =[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer =NULL;
    CVReturn status =CVPixelBufferCreate(kCFAllocatorDefault,size.width,size.height,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options,&pxbuffer);
    
    NSParameterAssert(status ==kCVReturnSuccess && pxbuffer !=NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer,0);
    void *pxdata =CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata !=NULL);
    
    CGColorSpaceRef rgbColorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata,size.width,size.height,8,4*size.width,rgbColorSpace,kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    
    CGContextDrawImage(context,CGRectMake(0,0,size.width,size.height),image);//CGImageGetWidth(image),CGImageGetHeight(image)), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer,0);
    
    return pxbuffer;
}

@end
