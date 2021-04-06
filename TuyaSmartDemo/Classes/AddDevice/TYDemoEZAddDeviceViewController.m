//
//  TYAddDeviceViewController.m
//  TuyaSmartHomeKit_Example
//
//  Created by 盖剑秋 on 2018/11/9.
//  Copyright © 2018 xuchengcheng. All rights reserved.
//

#import "TYDemoEZAddDeviceViewController.h"
#import "TYDemoConfiguration.h"
#import "TYDemoAddDeviceUtils.h"
#import <TuyaSmartActivatorKit/TuyaSmartActivatorKit.h>
#import "TPDemoUtils.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreImage/CoreImage.h>
/**
 
 @remark 2.4G WIFI environment is essential.
 @remark If your Xcode version is above 10.0, turn on 'Access WIFI Information' of your project before running on device.

 doc link
 
 en:https://tuyainc.github.io/tuyasmart_home_ios_sdk_doc/en/resource/Activator.html#network-configuration
 zh-hans:https://tuyainc.github.io/tuyasmart_home_ios_sdk_doc/zh-hans/resource/Activator.html#%E8%AE%BE%E5%A4%87%E9%85%8D%E7%BD%91

 */

@interface TYDemoEZAddDeviceViewController () <TuyaSmartActivatorDelegate>

@property (nonatomic, strong) UITextField *ssidField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextView *console;

//二维码
@property(nonatomic, strong)UIImageView *qrImgv;
@property(nonatomic, assign)CGFloat width_qr;

@end

@implementation TYDemoEZAddDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initView];
    
}

#pragma mark - Action

- (void)setupWiFiAction {
    //根据家庭id请求token
    WEAKSELF_AT
    id<TYDemoDeviceListModuleProtocol> impl = [[TYDemoConfiguration sharedInstance] serviceOfProtocol:@protocol(TYDemoDeviceListModuleProtocol)];
    long long homeId = [impl currentHomeId];
    [[TuyaSmartActivator sharedInstance] getTokenWithHomeId:homeId success:^(NSString *token) {
        NSString *info = [NSString stringWithFormat:@"%@: token fetched, token is %@",NSStringFromSelector(_cmd),token];
        [weakSelf_AT appendConsoleLog:info];
        
        NSDictionary *dictionary = @{
            @"s": self.ssidField.text,
            @"p": self.passwordField.text,
            @"t": token
        };
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
        NSString *wifiJsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [weakSelf_AT appendConsoleLog:wifiJsonStr];
        NSLog(@"可生成二维码用于配网");
        [self setupQRCodeWithContent:wifiJsonStr];
    } failure:^(NSError *error) {
        NSString *info = [NSString stringWithFormat:@"%@: token fetch failed, error message is %@",NSStringFromSelector(_cmd),error.localizedDescription];
        [weakSelf_AT appendConsoleLog:info];
    }];
    
}

#pragma mark - TuyaSmartActivatorDelegate

- (void)activator:(TuyaSmartActivator *)activator didReceiveDevice:(TuyaSmartDeviceModel *)deviceModel error:(NSError *)error {
    NSString *info = [NSString stringWithFormat:@"%@: Finished!", NSStringFromSelector(_cmd)];
    [self appendConsoleLog:info];
    if (error) {
        info = [NSString stringWithFormat:@"%@: Error-%@!", NSStringFromSelector(_cmd), error.localizedDescription];
        [self appendConsoleLog:info];
    } else {
        info = [NSString stringWithFormat:@"%@: Success-You've added device %@ successfully!", NSStringFromSelector(_cmd), deviceModel.name];
        [self appendConsoleLog:info];
    }
}

#pragma Mark - private

- (void)checkLocationAndWifiStatus {
    if (![[TYDemoAddDeviceUtils sharedInstance] currentNetworkStatus]) {
        UIAlertController *wifiAlert = [UIAlertController alertControllerWithTitle:@"ty_ez_current_no_wifi" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"ty_ap_connect_go" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[TYDemoAddDeviceUtils sharedInstance] gotoSettingWifi];
        }];
        [wifiAlert addAction:action];
        [self presentViewController:wifiAlert animated:YES completion:nil];
    }
    
    // get the current authorization status of the application
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    // get the current wifi name
    NSString *ssid = [TuyaSmartActivator currentWifiSSID];
    
    if (@available(iOS 13, *)) {
        if (!ssid || ssid.length == 0) {
            if (![CLLocationManager locationServicesEnabled]) {
                
            }
            
            if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusNotDetermined || status == kCLAuthorizationStatusRestricted) {
                UIAlertController *wifiAlert = [UIAlertController alertControllerWithTitle:@"ty_activator_locationAlert_tips" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"ty_activator_locationAlert_settingNow" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                [wifiAlert addAction:action];
                [self presentViewController:wifiAlert animated:YES completion:nil];
            }
        }
    }
}

- (void)appendConsoleLog:(NSString *)logString {
    NSLog(@"console:%@", logString);
    
    if (!logString) {
        logString = [NSString stringWithFormat:@"%@ : param error",NSStringFromSelector(_cmd)];
    }
    NSString *result = self.console.text?:@"";
    result = [[result stringByAppendingString:logString] stringByAppendingString:@"\n"];
    self.console.text = result;
    [self.console scrollRangeToVisible:NSMakeRange(result.length, 1)];
}

- (void)setupQRCodeWithContent:(NSString *)content {
    // 1. 创建一个二维码滤镜实例(CIFilter)
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 滤镜恢复默认设置
    [filter setDefaults];
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    // 使用KVC的方式给filter赋值
    [filter setValue:data forKeyPath:@"inputMessage"];

    // 3. 生成二维码
    CIImage *outputImage = [filter outputImage];
    UIImage *resultImage = [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:self.width_qr];
    self.qrImgv.image = resultImage;
}

/**
* 调用该方法处理图像变清晰
* 根据CIImage生成指定大小的UIImage
*
* @param image CIImage
* @param size 图片宽度以及高度
*/
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size {
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));

    //1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);

    //2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

#pragma mark - UI

- (void)initView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.topBarView.leftItem = self.leftBackItem;
    self.centerTitleItem.title = @"添加设备WiFi";
    self.topBarView.centerItem = self.centerTitleItem;
    
    CGFloat currentY = self.topBarView.height;
    currentY += 10;
    
    //first line.
    CGFloat labelWidth = 75;
    CGFloat textFieldWidth = APP_SCREEN_WIDTH - labelWidth - 30;
    CGFloat labelHeight = 44;
    
    UILabel *ssidKeyLabel = [sharedAddDeviceUtils() keyLabel];
    ssidKeyLabel.text = @"ssid:";
    ssidKeyLabel.frame = CGRectMake(10, currentY, labelWidth, labelHeight);
    [self.view addSubview:ssidKeyLabel];
    
    self.ssidField = [sharedAddDeviceUtils() textField];
    self.ssidField.placeholder = @"Input your wifi ssid";
    self.ssidField.frame = CGRectMake(labelWidth + 20, currentY, textFieldWidth, labelHeight);
    [self.view addSubview:self.ssidField];
    currentY += labelHeight;
    NSString *ssid = [TuyaSmartActivator currentWifiSSID];
    if (ssid.length) {
        self.ssidField.text = ssid;
    }
    //second line.
    currentY += 10;
    UILabel *passwordKeyLabel = [sharedAddDeviceUtils() keyLabel];
    passwordKeyLabel.text = @"password:";
    passwordKeyLabel.frame = CGRectMake(10, currentY, labelWidth, labelHeight);
    [self.view addSubview:passwordKeyLabel];
    
    self.passwordField = [sharedAddDeviceUtils() textField];
    self.passwordField.placeholder = @"password of wifi";
    self.passwordField.frame = CGRectMake(labelWidth + 20, currentY, textFieldWidth, labelHeight);
    [self.view addSubview:self.passwordField];
    currentY += labelHeight;
    
    //third line.
    currentY += 10;
    UIButton *QRModeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    QRModeButton.layer.cornerRadius = 5;
    QRModeButton.frame = CGRectMake(10, currentY, APP_SCREEN_WIDTH - 20, labelHeight);
    [QRModeButton setTitle:@"Generate QR Code" forState:UIControlStateNormal];
    QRModeButton.backgroundColor = UIColor.orangeColor;
    [QRModeButton addTarget:self action:@selector(setupWiFiAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:QRModeButton];
    currentY += labelHeight;
    
    //forth line.
    currentY += 10;
    UILabel *titleLabel = [sharedAddDeviceUtils() keyLabel];
    titleLabel.text = @"console:";
    titleLabel.frame = CGRectMake(10, currentY, labelWidth, labelHeight);
    [self.view addSubview:titleLabel];
    currentY += labelHeight;
    
    //fifth line.
    self.console = [UITextView new];
    self.console.frame = CGRectMake(10, currentY, APP_SCREEN_WIDTH - 20, 120);
    self.console.layer.borderColor = UIColor.blackColor.CGColor;
    self.console.layer.borderWidth = 1;
    [self.view addSubview:self.console];
    self.console.editable = NO;
    self.console.layoutManager.allowsNonContiguousLayout = NO;
    self.console.backgroundColor = HEXCOLOR(0xededed);
    currentY += self.console.height;
    
    CGFloat y_qr = currentY + 5;
    self.width_qr = APP_SCREEN_HEIGHT - currentY - 10;
    CGFloat x_qr = (APP_SCREEN_WIDTH - self.width_qr) / 2;
    
    self.qrImgv = [[UIImageView alloc] init];
    self.qrImgv.frame = CGRectMake(x_qr, y_qr, self.width_qr, self.width_qr);
    self.qrImgv.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.qrImgv];
}

@end
