//
//  EQSPortalItemListView.h
//  EsriQuickStartApp
//
//  Created by Nicholas Furness on 6/14/12.
//  Copyright (c) 2012 ESRI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EQSPortalItemListViewController.h"

#define kEQSNotification_BasemapSelected @"BasemapSelected"

@interface EQSPortalItemListView : UIScrollView
@property (nonatomic, strong) IBOutlet EQSPortalItemListViewController *viewController;

- (AGSPortalItem *) addPortalItem:(NSString *)portalItemID;
@end
