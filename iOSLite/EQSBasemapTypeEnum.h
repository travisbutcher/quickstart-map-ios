//
//  EQSBasemapTypeEnum.h
//  iOSLite
//
//  Created by Nicholas Furness on 5/25/12.
//  Copyright (c) 2012 ESRI. All rights reserved.
//

#ifndef iOSLite_EQSBasemapTypeEnum_h
#define iOSLite_EQSBasemapTypeEnum_h

typedef enum {
    EQSBasemapTypeStreet = 1,
    EQSBasemapTypeSatellite = 2,
    EQSBasemapTypeHybrid = 3,
    EQSBasemapTypeCanvas = 4,
    EQSBasemapTypeNationalGeographic = 5,
    EQSBasemapTypeTopographic = 6,
    EQSBasemapTypeOpenStreetMap = 7,
    
    EQSBasemapTypeFirst = EQSBasemapTypeStreet,
    EQSBasemapTypeLast = EQSBasemapTypeOpenStreetMap
} EQSBasemapType;

#endif