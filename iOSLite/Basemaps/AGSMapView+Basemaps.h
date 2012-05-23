//
//  EDNMapViewLite+Basemaps.h
//  iOSLite
//
//  Created by Nicholas Furness on 5/9/12.
//  Copyright (c) 2012 ESRI. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>
#import "EDNLiteHelper.h"

@interface AGSMapView (Basemaps)
- (void) setBasemap:(EDNLiteBasemapType)basemapType;
@end