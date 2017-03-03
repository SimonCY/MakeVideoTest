//
//  HeaderView.m
//  MakeVideoTest
//
//  Created by RRTY on 17/2/24.
//  Copyright © 2017年 deepAI. All rights reserved.
//

#import "HeaderView.h"

@implementation HeaderView
+ (HeaderView *)headerViewWithCollectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    HeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Reuserbleview" forIndexPath:indexPath];
    headerView.backgroundColor = [UIColor blueColor];

    return headerView;
}
@end
