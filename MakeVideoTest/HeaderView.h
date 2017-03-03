//
//  HeaderView.h
//  MakeVideoTest
//
//  Created by RRTY on 17/2/24.
//  Copyright © 2017年 deepAI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HeaderView : UICollectionReusableView

+ (HeaderView *)headerViewWithCollectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

@end
