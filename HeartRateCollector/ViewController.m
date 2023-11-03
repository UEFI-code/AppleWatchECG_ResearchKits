//
//  ViewController.m
//  HeartRateCollector
//
//  Created by uefi on 2023/11/03.
//

#import "ViewController.h"

#import <HealthKit/HealthKit.h>

#import <CoreLocation/CoreLocation.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *mylabel;
@property (nonatomic, strong) HKHealthStore *healthStore;
@property (nonatomic, strong) NSTimer *heartRateTimer;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation ViewController
  
- (void)viewDidLoad {
    [super viewDidLoad];
    self.healthStore = [[HKHealthStore alloc] init];
    self.heartRateTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(queryHeartBeatData) userInfo:nil repeats:YES];
    NSSet *readDataTypes = [NSSet setWithObjects:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate], nil];
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
        if (success) {
            //[self subscribeToHeartBeatChanges];
            [self.heartRateTimer fire];
        } else {
            NSLog(@"Unauth：%@", error);
        }
    }];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.allowsBackgroundLocationUpdates = YES;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (void)queryHeartBeatData {
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate] predicate:nil limit:1 sortDescriptors:@[timeSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (error) {
            NSLog(@"Failed Query：%@", error);
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.mylabel.text = [NSString stringWithFormat:@"Failed Query：%@", error];
                return;
            });
        }
        if (results.count > 0) {
            HKQuantitySample *sample = results.firstObject;
            HKQuantity *quantity = sample.quantity;
            NSLog(@"Hearbeat：%@ bpm", quantity);
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.mylabel.text = [NSString stringWithFormat:@"Hearbeat：%@", quantity];
            });
            return;
        }
    }];
    [self.healthStore executeQuery:query];
}

@end
