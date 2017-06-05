//
//  ViewController.m
//  JMNetWorkTest
//
//  Created by 雷建民 on 16/10/12.
//  Copyright © 2016年 leijianmin. All rights reserved.
//

#import "ViewController.h"
#import "JMHttpRequestMethod.h"

static NSString *url = @"http://open3.bantangapp.com/recommend/index?app_installtime=1453382654.838161&app_versions=5.3.1&channel_name=appStore&client_id=bt_app_ios&client_secret=9c1e6634ce1c5098e056628cd66a17a5&os_versions=9.2&page=0&pagesize=20&screensize=750&track_device_info=iPhone7%2C2&track_deviceid=8C446621-00E5-4909-8131-131C3C2EF7C7&v=10";

static NSString *url1 = @"http://open3.bantangapp.com/topic/list?app_installtime=1453382654.838161&app_versions=5.3.1&channel_name=appStore&client_id=bt_app_ios&client_secret=9c1e6634ce1c5098e056628cd66a17a5&os_versions=9.2&page=0&pagesize=20&scene=8&screensize=750&track_device_info=iPhone7%2C2&track_deviceid=8C446621-00E5-4909-8131-131C3C2EF7C7&v=10";

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"沙盒路径 = %@",NSHomeDirectory());
    [JMHttpRequestMethod sharedMethod].isDebug = NO;
}

- (IBAction)requestAction:(id)sender
{
        
        [JMHttpRequestMethod getWithUrl:url refreshCache:YES success:^(id responseObject) {
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
            self.textView.text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            // [JMHttpRequestMethod cleanNetWorkRefreshCache];
            NSLog(@"cache size is  %@", [JMHttpRequestMethod fileSizeWithDBPath]);
        } fail:^(NSError *error) {
            
        }];
 
    

        
        [JMHttpRequestMethod getWithUrl:url1 refreshCache:YES success:^(id responseObject) {                     
            
            NSLog(@"cache size is  %@", [JMHttpRequestMethod fileSizeWithDBPath]);
            
        } fail:^(NSError *error) {
            
        }];
    
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
