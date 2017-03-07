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


//生成caches目录下不带后缀名的一个以时间戳为名的新文件路径
- (NSString *)newTimeStrFilePath {
    
    //生成时间戳
    long recordTime = (NSInteger)[[NSDate date] timeIntervalSince1970]*1000;
    NSString *timeString = [NSString stringWithFormat:@"%ld",recordTime];
    
    //生成路径
    NSArray *CachesPaths =NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    NSString *filePath =[[CachesPaths objectAtIndex:0] stringByAppendingPathComponent:timeString];
    return filePath;
}

#pragma mark - 多张图片合成视频

- (NSString *)newMP4FilePath{
    return [NSString stringWithFormat:@"%@.mp4",[self newTimeStrFilePath]];
}

- (void)compressedMovieWithImages:(NSArray *)images completionHandlerOnMainThread:(void (^)(NSString *))handler {
    NSAssert(images.count, @"源图片数组为空");
    
    NSLog(@"开始合成");
    //NSString *moviePath = [[NSBundle mainBundle]pathForResource:@"Movie" ofType:@"mov"];
    NSString *moviePath = [self newMP4FilePath];
    

    
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

#pragma mark - 音频

//抽取原视频的音频与需要的音乐混合
-(void)addmusic:(id)sender
{
    
    
    AVMutableComposition *composition =[AVMutableComposition composition];
    NSMutableArray *audioMixParams =[[NSMutableArray alloc]initWithObjects:nil];
    
    //录制的视频
    NSURL *video_inputFileUrl =[NSURL fileURLWithPath:self.videoPath];
    AVURLAsset *songAsset =[AVURLAsset URLAssetWithURL:video_inputFileUrl options:nil];
    CMTime startTime =CMTimeMakeWithSeconds(0,songAsset.duration.timescale);
    CMTime trackDuration =songAsset.duration;
    
    //获取视频中的音频素材
    [self setUpAndAddAudioAtPath:video_inputFileUrltoComposition:composition start:startTimedura:trackDuration offset:CMTimeMake(14*44100,44100)];
    
    //本地要插入的音乐
    NSString *bundleDirectory =[[NSBundle mainBundle]bundlePath];
    NSString *path = [bundleDirectory stringByAppendingPathComponent:@"30secs.mp3"];
    NSURL *assetURL2 =[NSURL fileURLWithPath:path];
    //获取设置完的本地音乐素材
    [self setUpAndAddAudioAtPath:assetURL2toComposition:compositionstart:startTimedura:trackDurationoffset:CMTimeMake(0,44100)];
    
    //创建一个可变的音频混合
    AVMutableAudioMix *audioMix =[AVMutableAudioMix audioMix];
    audioMix.inputParameters =[NSArray arrayWithArray:audioMixParams];//从数组里取出处理后的音频轨道参数
    
    //创建一个输出
    AVAssetExportSession *exporter =[[AVAssetExportSession alloc]
                                     initWithAsset:composition
                                     presetName:AVAssetExportPresetAppleM4A];
    exporter.audioMix = audioMix;
    exporter.outputFileType=@"com.apple.m4a-audio";
    NSString* fileName =[NSString stringWithFormat:@"%@.mov",@"overMix"];
    //输出路径
    NSString *exportFile =[NSString stringWithFormat:@"%@/%@",[self getLibarayPath], fileName];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:exportFile]) {
        [[NSFileManager defaultManager] removeItemAtPath:exportFile error:nil];
    }
    NSLog(@"是否在主线程1%d",[NSThread isMainThread]);
    NSLog(@"输出路径===%@",exportFile);
    
    NSURL *exportURL =[NSURL fileURLWithPath:exportFile];
    exporter.outputURL = exportURL;
    self.mixURL =exportURL;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        int exportStatus =(int)exporter.status;
        switch (exportStatus){
            caseAVAssetExportSessionStatusFailed:{
                NSError *exportError =exporter.error;
                NSLog(@"错误，信息: %@", exportError);
                
                break;
            }
            caseAVAssetExportSessionStatusCompleted:{
                NSLog(@"是否在主线程2%d",[NSThread isMainThread]);
                NSLog(@"成功");
                //最终混合
                [self theVideoWithMixMusic];
                break;
            }
        }
    }];
    
}

//最终音频和视频混合
-(void)theVideoWithMixMusic
{
    NSError *error =nil;
    NSFileManager *fileMgr =[NSFileManager defaultManager];
    NSString *documentsDirectory =[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *videoOutputPath =[documentsDirectory stringByAppendingPathComponent:@"test_output.mp4"];
    if ([fileMgr removeItemAtPath:videoOutputPatherror:&error]!=YES) {
        NSLog(@"无法删除文件，错误信息：%@",[error localizedDescription]);
    }
    
    //声音来源路径（最终混合的音频）
    NSURL   *audio_inputFileUrl =self.mixURL;
    
    //视频来源路径
    NSURL   *video_inputFileUrl = [NSURLfileURLWithPath:self.videoPath];
    
    //最终合成输出路径
    NSString *outputFilePath =[documentsDirectorystringByAppendingPathComponent:@"final_video.mp4"];
    NSURL   *outputFileUrl = [NSURLfileURLWithPath:outputFilePath];
    
    if([[NSFileManagerdefaultManager]fileExistsAtPath:outputFilePath])
        [[NSFileManagerdefaultManager]removeItemAtPath:outputFilePatherror:nil];
    
    CMTime nextClipStartTime =kCMTimeZero;
    
    //创建可变的音频视频组合
    AVMutableComposition* mixComposition =[AVMutableCompositioncomposition];
    
    //视频采集
    AVURLAsset* videoAsset =[[AVURLAssetalloc]initWithURL:video_inputFileUrloptions:nil];
    CMTimeRange video_timeRange =CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
    AVMutableCompositionTrack*a_compositionVideoTrack = [mixCompositionaddMutableTrackWithMediaType:AVMediaTypeVideopreferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrackinsertTimeRange:video_timeRangeofTrack:[[videoAssettracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0]atTime:nextClipStartTimeerror:nil];
    
    //声音采集
    AVURLAsset* audioAsset =[[AVURLAssetalloc]initWithURL:audio_inputFileUrloptions:nil];
    CMTimeRange audio_timeRange =CMTimeRangeMake(kCMTimeZero,videoAsset.duration);//声音长度截取范围==视频长度
    AVMutableCompositionTrack*b_compositionAudioTrack = [mixCompositionaddMutableTrackWithMediaType:AVMediaTypeAudiopreferredTrackID:kCMPersistentTrackID_Invalid];
    [b_compositionAudioTrackinsertTimeRange:audio_timeRangeofTrack:[[audioAssettracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0]atTime:nextClipStartTimeerror:nil];
    
    //创建一个输出
    AVAssetExportSession* _assetExport =[[AVAssetExportSessionalloc]initWithAsset:mixCompositionpresetName:AVAssetExportPresetMediumQuality];
    _assetExport.outputFileType =AVFileTypeQuickTimeMovie;
    _assetExport.outputURL =outputFileUrl;
    _assetExport.shouldOptimizeForNetworkUse=YES;
    self.theEndVideoURL=outputFileUrl;
    
    [_assetExportexportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         [MBProgressHUDhideHUDForView:self.viewanimated:YES];
         //播放
         NSURL*url = [NSURLfileURLWithPath:outputFilePath];
         MPMoviePlayerViewController *theMovie =[[MPMoviePlayerViewControlleralloc]initWithContentURL:url];
         [selfpresentMoviePlayerViewControllerAnimated:theMovie];
         theMovie.moviePlayer.movieSourceType=MPMovieSourceTypeFile;
         [theMovie.moviePlayerplay];
     }
     ];
    NSLog(@"完成！输出路径==%@",outputFilePath);
}

//通过文件路径建立和添加音频素材
- (void)setUpAndAddAudioAtPath:(NSURL*)assetURLtoComposition:(AVMutableComposition*)composition start:(CMTime)startdura:(CMTime)duraoffset:(CMTime)offset{
    
    AVURLAsset *songAsset =[AVURLAssetURLAssetWithURL:assetURLoptions:nil];
    
    AVMutableCompositionTrack *track =[compositionaddMutableTrackWithMediaType:AVMediaTypeAudiopreferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *sourceAudioTrack =[[songAssettracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
    
    NSError *error =nil;
    BOOL ok =NO;
    
    CMTime startTime = start;
    CMTime trackDuration = dura;
    CMTimeRange tRange =CMTimeRangeMake(startTime,trackDuration);
    
    //设置音量
    //AVMutableAudioMixInputParameters（输入参数可变的音频混合）
    //audioMixInputParametersWithTrack（音频混音输入参数与轨道）
    AVMutableAudioMixInputParameters *trackMix =[AVMutableAudioMixInputParametersaudioMixInputParametersWithTrack:track];
    [trackMixsetVolume:0.8fatTime:startTime];
    
    //素材加入数组
    [audioMixParamsaddObject:trackMix];
    
    //Insert audio into track  //offsetCMTimeMake(0, 44100)
    ok = [trackinsertTimeRange:tRangeofTrack:sourceAudioTrackatTime:kCMTimeInvaliderror:&error];
}

#pragma mark - 保存路径
-(NSString*)getLibarayPath
{
    NSFileManager *fileManager =[NSFileManagerdefaultManager];
    
    NSArray* paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString* path = [pathsobjectAtIndex:0];
    
    NSString *movDirectory = [pathstringByAppendingPathComponent:@"tmpMovMix"];
    
    [fileManagercreateDirectoryAtPath:movDirectorywithIntermediateDirectories:YESattributes:nilerror:nil];
    
    return movDirectory;
    
}





#pragma mark - buffer转UIImage
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
