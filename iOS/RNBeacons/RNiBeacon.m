
//  Created by Christopher on 7/16/15.

#import "RNiBeacon.h"
#import "RCTEventDispatcher.h"
#import "RCTConvert.h"

static NSString* didEnterRegion = @"didEnterRegion";
static NSString* didExitRegion = @"didExitRegion";
static NSString* didRangeBeacons = @"didRangeBeacons";
static NSString* didChangeAuthorizationStatus = @"didChangeAuthorizationStatus";

@implementation RNiBeacon

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

- (instancetype)init
{
  if (self = [super init]) {
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
      [self.locationManager requestAlwaysAuthorization];
    }
    
    self.locationManager.delegate = self;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
  }
  
  return self;
}

- (NSString *)proximityString:(CLProximity)proximity {
  switch (proximity) {
    case CLProximityUnknown:    return @"unknown";
    case CLProximityImmediate:  return @"immediate";
    case CLProximityNear:       return @"near";
    case CLProximityFar:        return @"far";
    default:                    return @"";
  }
}

- (NSString *)authorizationString:(CLAuthorizationStatus)status {
  switch(status) {
    case kCLAuthorizationStatusNotDetermined:       return @"notDetermined";
    case kCLAuthorizationStatusRestricted:          return @"restricted";
    case kCLAuthorizationStatusDenied:              return @"denied";
    case kCLAuthorizationStatusAuthorizedAlways:    return @"authorizedAlways";
    case kCLAuthorizationStatusAuthorizedWhenInUse: return @"authorizedWhenInUse";
  }
}

- (NSDictionary *)constantsToExport
{
  return @{ @"authorizationStatus": [self authorizationString:[CLLocationManager authorizationStatus]]};
}

RCT_REMAP_METHOD(getAuthorizationStatusAsync,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  resolve(@[[self authorizationString:[CLLocationManager authorizationStatus]]]);
}

RCT_EXPORT_METHOD(requestAlwaysAuthorization)
{
  if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
    [self.locationManager requestAlwaysAuthorization];
  }
}

RCT_EXPORT_METHOD(requestWhenInUseAuthorization)
{
  if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
    [self.locationManager requestWhenInUseAuthorization];
  }
}

RCT_EXPORT_METHOD(createBeaconRegion: (NSString *)beaconUUID regionIdentifier:(NSString *) regionIdentifier) {
  NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:beaconUUID];
  NSString *identifier = regionIdentifier;
  self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:identifier];
  NSLog(@"RCT - createBeaconRegion");
}

RCT_EXPORT_METHOD(startMonitoringForRegion) {
  [self.locationManager startMonitoringForRegion:self.beaconRegion];
  NSLog(@"RCT - startMonitoringForRegion");
}

RCT_EXPORT_METHOD(stopMonitoringForRegion) {
  [self.locationManager stopMonitoringForRegion:self.beaconRegion];
  NSLog(@"RCT - stopMonitoringForRegion");
}

RCT_EXPORT_METHOD(startRangingBeaconsInRegion) {
  [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
  NSLog(@"RCT - startRangingBeaconsInRegion");
}

RCT_EXPORT_METHOD(stopRangingBeaconsInRegion) {
  [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
  NSLog(@"RCT - stopRangingBeaconsInRegion");
}

RCT_EXPORT_METHOD(startUpdatingLocation) {
  [self.locationManager startUpdatingLocation];
  NSLog(@"RCT - startUpdatingLocation");
}

RCT_EXPORT_METHOD(stopUpdatingLocation) {
  [self.locationManager stopUpdatingLocation];
  NSLog(@"RCT - stopUpdatingLocation");
}

// didEnterRegion

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLBeaconRegion *)region {
  
  // Safety Check!
  if (![self.beaconRegion isEqual:region]) return;
  
  /**
   * Uncomment to automatically start ranging and updating
   */
  
  //    [manager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
  //    [self.locationManager startUpdatingLocation];
  
  NSDictionary *event = @{
                          @"region": region.identifier,
                          @"uuid": [region.proximityUUID UUIDString],
                          };
  
  NSLog(@"You entered the region.");
  [self.bridge.eventDispatcher sendDeviceEventWithName:didEnterRegion body:event];
  
}

// didExitRegion

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLBeaconRegion *)region {
  
  /**
   * Uncomment to automatically stop ranging and updating
   */
  
  //    [manager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
  //    [self.locationManager stopUpdatingLocation];
  
  NSDictionary *event = @{
                          @"region": region.identifier,
                          @"uuid": [region.proximityUUID UUIDString],
                          };
  
  NSLog(@"You exited the region.");
  [self.bridge.eventDispatcher sendDeviceEventWithName:didExitRegion body:event];
  
}

// didRangeBeacons

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
  NSMutableArray *beaconArray = [[NSMutableArray alloc] init];
  
  for (CLBeacon *beacon in beacons) {
    
    [beaconArray addObject:@{
                             @"uuid": beacon.proximityUUID.UUIDString,
                             @"major": beacon.major,
                             @"minor": beacon.minor,
                             @"rssi": [NSNumber numberWithInteger:beacon.rssi],
                             @"accuracy": [NSNumber numberWithDouble: beacon.accuracy],
                             @"proximity": [self proximityString: beacon.proximity]
                             }];
  }
  
  NSDictionary *event = @{
                          @"region": @{
                              @"identifier": region.identifier,
                              @"uuid": [region.proximityUUID UUIDString],
                              },
                          @"beacons": beaconArray
                          };
  
  [self.bridge.eventDispatcher sendDeviceEventWithName:didRangeBeacons body:event];
  
}


// didChangeAuthorizationStatus

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  
  NSString *authorizationStatus = [self authorizationString:status];
  NSLog(@"Authorization status changed to: %@", authorizationStatus);
  
  [self.bridge.eventDispatcher sendDeviceEventWithName:didChangeAuthorizationStatus body:authorizationStatus];
}

// rangingBeaconsDidFailForRegion

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
  NSLog(@"Failed ranging region: %@", error);
}

// monitoringDidFailForRegion

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
  NSLog(@"Failed monitoring region: %@", error);
}

// didFailWithError

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  NSLog(@"Location manager failed: %@", error);
}

@end
