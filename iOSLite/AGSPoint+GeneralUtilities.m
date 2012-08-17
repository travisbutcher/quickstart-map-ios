//
//  AGSPoint+GeneralUtilities.m
//  iOSLite
//
//  Created by Nicholas Furness on 6/21/12.
//  Copyright (c) 2012 ESRI. All rights reserved.
//

#import "AGSPoint+GeneralUtilities.h"
#import "EQSHelper.h"

@implementation AGSPoint (GeneralUtilities)
+ (AGSPoint *) pointFromLat:(double)latitude Long:(double)longitude
{
	return [EQSHelper getWebMercatorAuxSpherePointFromLat:latitude Long:longitude];
}

- (double) latitude
{
	AGSPoint *geoPt = [EQSHelper getWGS84PointFromPoint:self];
	return geoPt.y;
}

- (double) longitude
{
	AGSPoint *geoPt = [EQSHelper getWGS84PointFromPoint:self];
	return geoPt.x;
}
@end
