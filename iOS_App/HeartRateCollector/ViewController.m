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
@property (weak, nonatomic) IBOutlet UITextField *srvurl;
@property (weak, nonatomic) IBOutlet UILabel *mylabel;
@property (nonatomic, strong) HKHealthStore *healthStore;
@property (nonatomic, strong) NSTimer *heartRateTimer;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation ViewController
- (IBAction)changedtxt:(id)sender {
    // save to user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.srvurl.text forKey:@"srvurl"];
    [defaults synchronize];
}

- (IBAction)startecg:(id)sender {
    self.healthStore = [[HKHealthStore alloc] init];
    self.heartRateTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(queryHeartBeatData) userInfo:nil repeats:YES];
    NSSet *readDataTypes = [NSSet setWithObjects:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate], nil];
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
        if (success) {
            //[self subscribeToHeartBeatChanges];
            [self.heartRateTimer fire];
        } else {
            NSLog(@"Unauth: %@", error);
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // load default server url
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *srvurl = [defaults objectForKey:@"srvurl"];
    if (srvurl) {
        self.srvurl.text = srvurl;
    }
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.allowsBackgroundLocationUpdates = YES;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];

    // set keyboard dismiss when click outside of textfield
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)]];
}

- (void)queryHeartBeatData {
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate] predicate:nil limit:1 sortDescriptors:@[timeSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (error) {
            NSLog(@"Failed Query: %@", error);
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.mylabel.text = [NSString stringWithFormat:@"Failed Query: %@", error];
                return;
            });
        }
        if (results.count > 0) {
            HKQuantitySample *sample = results.firstObject;
            HKQuantity *quantity = sample.quantity;
            NSLog(@"Hearbeat: %@ bpm", quantity);
            dispatch_sync(dispatch_get_main_queue(), ^{
                // packing to a json data
                NSDictionary *dict = @{@"heart_rate": [NSString stringWithFormat:@"%@", quantity]};
                self.mylabel.text = [NSString stringWithFormat:@"%@", dict];
                // send to server
                NSURL *url = [NSURL URLWithString:self.srvurl.text];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                request.HTTPMethod = @"POST";
                request.HTTPBody = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
                NSURLSession *session = [NSURLSession sharedSession];
                // set timeout to 1 sec
                session.configuration.timeoutIntervalForRequest = 1.0f;
                session.configuration.timeoutIntervalForResource = 1.0f;
                NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        NSLog(@"Failed to send: %@", error);
                    }
                }];
                [task resume];
            });
            return;
        }
    }];
    [self.healthStore executeQuery:query];
}

@end
