
//  Created by Christopher on 7/16/15.

#import <CoreLocation/CoreLocation.h>
#import "RCTBridgeModule.h"

@interface RNiBeacon : NSObject <RCTBridgeModule, CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property CLProximity lastProximity;

@end
