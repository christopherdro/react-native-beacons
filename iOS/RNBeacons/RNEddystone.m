
//  Created by Christopher on 7/26/15.

#import "RCTEventDispatcher.h"
#import "RNEddyStone.h"
#import "ESSEddystone.h"

static NSString* didFindBeacon = @"didFindBeacon";
static NSString* didUpdateBeacon = @"didUpdateBeacon";
static NSString* didLoseBeacon = @"didLoseBeacon";

static NSString* UIDFrameType = @"uid";
static NSString* URLFrameType = @"url";
static NSString* TLMFrameType = @"tlm";

@implementation RNEddystone {
  ESSBeaconScanner *_scanner;
  NSMutableDictionary *_beacons;
}

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

- (instancetype)init
{
  if (self = [super init]) {
    _scanner = [[ESSBeaconScanner alloc] init];
    _scanner.delegate = self;
    _beacons = [[NSMutableDictionary alloc] init];
  }
  return self;
}

+ (NSArray *)prefixes
{
  static NSArray *_prefixes;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _prefixes = @[
                  @"http://www.",
                  @"https://www.",
                  @"http://",
                  @"https://"
                  ];
  });
  return _prefixes;
}

+ (NSArray *)suffixes
{
  static NSArray *_suffixes;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _suffixes = @[
                  @".com/",
                  @".org/",
                  @".edu/",
                  @".net/",
                  @".info/",
                  @".biz/",
                  @".gov/",
                  @".com",
                  @".org",
                  @".edu",
                  @".net",
                  @".info",
                  @".biz",
                  @".gov"
                  ];
  });
  return _suffixes;
}

RCT_EXPORT_METHOD(startScanning) {
  [_scanner startScanning];
}

RCT_EXPORT_METHOD(stopScanning) {
  [_scanner stopScanning];
}

RCT_EXPORT_METHOD(setOnLostTimeout: (NSNumber *)timeout) {
  _scanner.onLostTimeout = [timeout doubleValue];
}

- (void)beaconScanner:(ESSBeaconScanner *)scanner didFindBeacon:(NSObject *)beaconInfo {
  [_beacons setObject:convertBeaconInfoToDictionary(beaconInfo) forKey:convertHexToString([beaconInfo valueForKeyPath:@"beaconID.beaconID"])];
  [self.bridge.eventDispatcher sendDeviceEventWithName:didFindBeacon body:convertBeaconInfoToDictionary(beaconInfo)];
  
}

- (void)beaconScanner:(ESSBeaconScanner *)scanner didUpdateBeacon:(NSObject *)beaconInfo {
  // Although this returns a single beacons info, Let's go ahead and return all current beacons for tracking.
  [_beacons setObject:convertBeaconInfoToDictionary(beaconInfo) forKey:convertHexToString([beaconInfo valueForKeyPath:@"beaconID.beaconID"])];
  
  [self.bridge.eventDispatcher sendDeviceEventWithName:didUpdateBeacon body:_beacons];
  
}

- (void)beaconScanner:(ESSBeaconScanner *)scanner didLoseBeacon:(id)beaconInfo {
  [_beacons removeObjectForKey:convertHexToString([beaconInfo valueForKeyPath:@"beaconID.beaconID"])];
  [self.bridge.eventDispatcher sendDeviceEventWithName:didLoseBeacon body:convertBeaconInfoToDictionary(beaconInfo)];
  
}

NSDictionary *convertBeaconInfoToDictionary (NSObject *data) {
  NSData *beaconID = [data valueForKeyPath:@"beaconID.beaconID"];
  NSData *telemetry = [data valueForKey:@"telemetry"];
  NSNumber *RSSI = [data valueForKey:@"RSSI"];
  NSNumber *txPower = [data valueForKey:@"txPower"];
  NSString *frameType = [data valueForKey:@"frameType"];
  
  NSDictionary *dictionary, *tlmFrame;
  
  if (beaconID) {
    
    if (telemetry) {
      // NOTE: Framedata will be converted through JS. Will probably end up moving
      // forward parsing all eddystone frames  with JS.
      tlmFrame = @{
                   @"frameData": convertHexToString(telemetry)
                   };
    }
    
    if ([frameType isEqualToString:UIDFrameType]) {
      
      NSData *namespaceID = [beaconID subdataWithRange:NSMakeRange(0, 10)];
      NSData *instanceID = [beaconID subdataWithRange:NSMakeRange(10, 6)];
      
      dictionary = @{
                     @"type": frameType,
                     @"namespaceID":  convertHexToString(namespaceID),
                     @"instanceID":  convertHexToString(instanceID),
                     @"rssi": RSSI,
                     @"txPower":  txPower
                     };
      
    } else if ([frameType isEqualToString:URLFrameType]) {
      dictionary = @{
                     @"type": frameType,
                     @"url":  decodeURL(beaconID),
                     @"rssi":  RSSI,
                     @"txPower": txPower
                     };
    }
  }
  
  // Add TLM data object to dictionary if it exists
  
  if ([tlmFrame count]) {
    NSMutableDictionary *frameData = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    [frameData setObject:[NSDictionary dictionaryWithDictionary:tlmFrame] forKey:@"tlm"];
    return frameData;
  } else {
    return dictionary;
  }
  
}

NSMutableString *convertHexToString (NSData *data) {
  
  NSMutableString *string = [NSMutableString string];
  const char *dataBytes = [data bytes];
  
  for (int i = 0; i < [data length]; i++) {
    [string appendFormat:@"%02hhx", (unsigned char)dataBytes[i]];
  }
  
  return string;
}

NSMutableString *decodeURL (NSData *data) {
  
  NSMutableString *decodedURL = [NSMutableString string];
  const char *dataBytes = [data bytes];
  
  NSArray *prefixes = [RNEddystone prefixes];
  NSArray *suffixes = [RNEddystone suffixes];
  
  if (dataBytes[0] < [prefixes count]) {
    [decodedURL appendFormat:@"%@",[prefixes objectAtIndex:dataBytes[0]]];
  }
  
  for (int i = 1; i < [data length]; i++)
  {
    if (dataBytes[i] < [suffixes count]) {
      [decodedURL appendFormat:@"%@",[suffixes objectAtIndex:dataBytes[i]]];
    } else {
      [decodedURL appendFormat:@"%C", (unsigned short)dataBytes[i]];
      
    }
  }
  
  return decodedURL;
}
@end
