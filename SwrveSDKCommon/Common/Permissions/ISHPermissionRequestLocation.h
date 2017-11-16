//
//  ISHPermissionRequestLocation.h
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 26.06.14.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import "ISHPermissionRequest.h"

#if defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)

@interface ISHPermissionRequestLocation : ISHPermissionRequest
@end

#endif //defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)
