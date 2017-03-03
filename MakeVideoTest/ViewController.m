//
//  ViewController.m
//  MakeVideoTest
//
//  Created by RRTY on 17/2/24.
//  Copyright © 2017年 deepAI. All rights reserved.
//

#import "ViewController.h"
#import "Cell.h"
#import "HeaderView.h"
#import "CYVideoMaker.h"
#import <MediaPlayer/MediaPlayer.h>

#import <AssetsLibrary/AssetsLibrary.h>

#define cellID @"cellID"

@interface ViewController ()<UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>

@property (nonatomic,strong) UICollectionView* collectionView;
@property (nonatomic,strong) UIButton* composedBtn;

@property (nonatomic,strong) NSMutableArray* images;

@property (nonatomic,strong) CYVideoMaker* videoMaker;

@property (nonatomic,strong) HeaderView* headerView;

@end

@implementation ViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadUI];
    
    self.videoMaker = [[CYVideoMaker alloc] init];
    
}
#pragma mark - loadData
- (NSMutableArray *)images {
    if (!_images) {
        _images = [NSMutableArray array];
        
        for (int i = 0; i < 50; i++) {
            NSString *imageName = [NSString stringWithFormat:@"%02d.jpg",i];
            NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
            NSAssert((image != nil), @"图片加载失败");
            [_images addObject:image];
        }
    }
    return _images;
}
#pragma mark - loadUI
- (void)loadUI {
    [self.view addSubview:self.collectionView];
    
    [self.view addSubview:self.composedBtn];
}

- (UIButton *)composedBtn {
    if (!_composedBtn) {
        _composedBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _composedBtn.frame = CGRectMake(50 , self.view.frame.size.height - 50 - 50, self.view.frame.size.width - 50 * 2, 50);
        [_composedBtn setTitle:@"composed" forState:UIControlStateNormal];
        _composedBtn.backgroundColor = [UIColor yellowColor];
        _composedBtn.layer.cornerRadius = 10;
        _composedBtn.layer.shadowOffset = CGSizeMake(5, 5);
        _composedBtn.layer.shadowOpacity = 0.8;
        _composedBtn.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        
        [_composedBtn addTarget:self action:@selector(compressedBtnClicked:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _composedBtn;
}

-(UICollectionView *)collectionView
{
    if (!_collectionView) {
        //将子视图的位置，大小和外观的控制权委托给一个单独的布局对象UICollectionViewLayout的对象
        //流式布局，较为常用
        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        
        //设置头部
        collectionViewLayout.headerReferenceSize = CGSizeMake(self.view.frame.size.width, 160);
        _collectionView = [[UICollectionView alloc]initWithFrame:self.view.frame collectionViewLayout:collectionViewLayout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        
        //注册CollectionViewCell，添加cell
        [_collectionView registerClass:[Cell class] forCellWithReuseIdentifier:cellID];
        //注册collectionViewHeaderView
        [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Reuserbleview"];
        
    }
    return _collectionView;
}

#pragma mark - clecked event
- (void)compressedBtnClicked:(UIButton *)btn {
    
    [self.videoMaker compressedMovieWithImages:self.images completionHandlerOnMainThread:^(NSString *videoPath) {
        
//        UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(videoDidFinishSaving), nil);
        NSLog(@"xianc %d",[[NSThread currentThread]isMainThread]);
        ALAssetsLibrary *library  = [[ALAssetsLibrary alloc] init];
        [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:videoPath]  completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                NSLog(@"Save video fail:%@",error);
            } else {
                NSLog(@"Save video succeed.");
                NSFileManager *fileManger = [[NSFileManager alloc] init];
                [fileManger removeItemAtURL:[NSURL fileURLWithPath:videoPath] error:nil];

            }
        }];
    }];
}

- (void)videoDidFinishSaving {
    NSLog(@"video save succeed");
}


#pragma mark - collectionViewDelegate
//定义展示的Section的个数
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

//定义展示的UICollectionViewCell的个数
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count;
}

//每个UICollectionView展示的内容
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Cell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    //自适应
//    [cell sizeToFit];
    cell.imageView.image = (UIImage *)self.images[indexPath.row];
    cell.label.text = [NSString stringWithFormat:@"img-%02ld",(long)indexPath.row];
    return cell;
    
}

//头部显示的内容
-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    HeaderView *headerView = [HeaderView headerViewWithCollectionView:collectionView viewForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
    self.headerView = headerView;
    return headerView;
    
}

#pragma mark - UICollectionFlowLayoutDelegate
//定义每个UICollectionViewCell 大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake((self.view.frame.size.width-30)/2,(self.view.frame.size.width-30)/2);
}
//定义每个UICollectionView的间距
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10, 10, 10, 10);
}

//定义每个UICollectionView,列与列之间的距离
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

//行与行之间的距离
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 10;
}

#pragma mark - UICollectionDelegate
//被选中时调用的方法
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}
//是否可以被选择
-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

@end
