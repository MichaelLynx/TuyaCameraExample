//
// TuyaFirmwareUpgradeInfo.h
// TuyaSmartDeviceCoreKit
//
// Copyright (c) 2014-2021 Tuya Inc. (https://developer.tuya.com)

#ifndef TuyaSmart_TuyaSmartFirmwareUpgradeModel
#define TuyaSmart_TuyaSmartFirmwareUpgradeModel

#import <Foundation/Foundation.h>

@interface TuyaSmartFirmwareUpgradeModel : NSObject

/// Upgrade copywriting.
@property (nonatomic, strong) NSString  *desc;

/// Equipment Type Copywriting.
@property (nonatomic, strong) NSString *typeDesc;

/// 0:No new version 1:There is a new version. 2:In the process of upgrading. 5:Waiting for the device to wake up.
@property (nonatomic, assign) NSInteger upgradeStatus;

/// Firmware version used in the new version.
@property (nonatomic, strong) NSString  *version;

/// Current firmware version in use.
@property (nonatomic, strong) NSString  *currentVersion;

/// Upgrade timeout (seconds)
@property (nonatomic, assign) NSInteger timeout;

/// 0:app remind upgrade. 2:app force upgrade. 3:detect upgrade.
@property (nonatomic, assign) NSInteger upgradeType;

/// Equipment Type.
@property (nonatomic, assign) NSInteger type;

/// Download URL of the upgrade firmware for Bluetooth devices.
@property (nonatomic, strong) NSString *url;

/// Firmware md5.
@property (nonatomic, strong) NSString *md5;

/// Size of the firmware package (byte).
@property (nonatomic, strong) NSString *fileSize;

/// Last upgrade time
@property (nonatomic, assign) long long lastUpgradeTime;

/// Firmware Release Date.
@property (nonatomic, assign) long long firmwareDeployTime;

/// Whether the upgrade device is controllable.  0 : controllable; 1 : not controllable.
@property (nonatomic, assign) BOOL controlType;

/// Tip text in firmware upgrade.
@property (nonatomic, strong) NSString *upgradingDesc;

/// The prompt text in the device download firmware, currently only nb devices have.
@property (nonatomic, strong) NSString *downloadingDesc;

@end

#endif
