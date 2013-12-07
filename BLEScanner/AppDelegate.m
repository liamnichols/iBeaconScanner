//
//  AppDelegate.m
//  BLEScanner
//
//  Created by Liam Nichols on 16/11/2013.
//  Copyright (c) 2013 Liam Nichols. All rights reserved.
//

@import IOBluetooth;

#import "AppDelegate.h"

static const NSTimeInterval kScanTimeInterval = 5.0;

@interface AppDelegate () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *manager;

@property (nonatomic, strong) NSMutableDictionary *beacons;

@property (nonatomic) BOOL canScan;
@property (nonatomic) BOOL isScanning;

@property (nonatomic, strong) NSTimer *scanTimer;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (self.manager.state == CBCentralManagerStatePoweredOn)
    {
        self.canScan = YES;
    }
    else
    {
        self.canScan = NO;
    }
    
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOff:
            [self.statusLabel setStringValue:@"Powered Off"];
            break;
        case CBCentralManagerStatePoweredOn:
            [self.statusLabel setStringValue:@"Powered On"];
            break;
        case CBCentralManagerStateResetting:
            [self.statusLabel setStringValue:@"Resetting"];
            break;
        case CBCentralManagerStateUnauthorized:
            [self.statusLabel setStringValue:@"Unauthorised"];
            break;
        case CBCentralManagerStateUnsupported:
            [self.statusLabel setStringValue:@"Unsupported"];
            break;
        case CBCentralManagerStateUnknown:
        default:
            [self.statusLabel setStringValue:@"Unknown"];
            break;
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSData *advData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
    if ([self advDataIsBeacon:advData])
    {
        NSMutableDictionary *beacon = [NSMutableDictionary dictionaryWithDictionary:[self getBeaconInfoFromData:advData]];
        [beacon setObject:RSSI forKey:@"RSSI"];

        [self.beacons setObject:beacon forKey:peripheral.identifier];
    }
}

- (BOOL)advDataIsBeacon:(NSData *)data
{
    //TODO: could this be cleaner?
    Byte expectingBytes [4] = { 0x4c, 0x00, 0x02, 0x15 };
    NSData *expectingData = [NSData dataWithBytes:expectingBytes length:sizeof(expectingBytes)];
    
    if (data.length > expectingData.length)
    {
        if ([[data subdataWithRange:NSMakeRange(0, expectingData.length)] isEqual:expectingData])
        {
            return YES;
        }
    }
    
    return NO;
}

- (NSDictionary *)getBeaconInfoFromData:(NSData *)data
{
    NSRange uuidRange = NSMakeRange(4, 16);
    NSRange majorRange = NSMakeRange(20, 2);
    NSRange minorRange = NSMakeRange(22, 2);
    NSRange powerRange = NSMakeRange(24, 1);
    
    Byte uuidBytes[16];
    [data getBytes:&uuidBytes range:uuidRange];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:uuidBytes];
    
    uint16_t majorBytes;
    [data getBytes:&majorBytes range:majorRange];
    uint16_t majorBytesBig = (majorBytes >> 8) | (majorBytes << 8);
    
    uint16_t minorBytes;
    [data getBytes:&minorBytes range:minorRange];
    uint16_t minorBytesBig = (minorBytes >> 8) | (minorBytes << 8);
    
    int8_t powerByte;
    [data getBytes:&powerByte range:powerRange];
    

    
    return @{ @"uuid" : uuid, @"major" : @(majorBytesBig), @"minor" : @(minorBytesBig), @"power" : @(powerByte) };
}

#pragma mark - Scanning

- (BOOL)startScanning
{
    if (self.canScan)
    {
        if (self.scanTimer)
            [self.scanTimer invalidate];
        
        NSTimeInterval duration = self.durationTextField.doubleValue;
        if (duration == 0)
        {
            duration = kScanTimeInterval;
            [self.durationTextField setDoubleValue:kScanTimeInterval];
        }
        
        self.beacons = nil;
        self.isScanning = YES;
        [self.manager scanForPeripheralsWithServices:nil options:nil];
        self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(stopScanning) userInfo:nil repeats:NO];
        [self.tableView reloadData];
        NSLog(@"started scanning");
        return YES;
    }
    NSLog(@"unable to start scan");
    return NO;
}

- (void)stopScanning
{
    [self.manager stopScan];
    self.isScanning = NO;
    [self.scanTimer invalidate];
    [self didStopScanning];
}

- (void)didStopScanning
{
    NSLog(@"scan complete");
    NSLog(@"beacons: %@",self.beacons);
    
    [self.tableView reloadData];
}

#pragma mark - Button Updating

-(void)setIsScanning:(BOOL)isScanning
{
    if (_isScanning != isScanning)
    {
        _isScanning = isScanning;
        
        if (isScanning)
        {
            [self.durationTextField setEnabled:NO];
            self.scanButton.title = @"Stop Scanning";
            self.scanButton.target = self;
            self.scanButton.action = @selector(stopScanning);
        }
        else if (self.canScan)
        {
            [self.durationTextField setEnabled:YES];
            self.scanButton.title = @"Start Scanning";
            self.scanButton.target = self;
            self.scanButton.action = @selector(startScanning);
        }
        else if (!self.canScan)
        {
            [self.durationTextField setEnabled:YES];
            self.scanButton.title = @"Start Scanning";
            self.scanButton.target = nil;
            self.scanButton.action = nil;
        }
    }
}

-(void)setCanScan:(BOOL)canScan
{
    if (_canScan != canScan)
    {
        _canScan = canScan;
        
        if (canScan)
        {
            [self.scanButton setEnabled:YES];
            [self.scanButton setTitle:@"Start Scanning"];
            [self.scanButton setTarget:self];
            [self.scanButton setAction:@selector(startScanning)];
        }
        else
        {
            [self.scanButton setEnabled:NO];
            [self.scanButton setTitle:@"Start Scanning"];
            [self.scanButton setTarget:self];
            [self.scanButton setAction:@selector(startScanning)];
        }
    }
}

#pragma mark - Lazy Loading

-(NSMutableDictionary *)beacons
{
    if (!_beacons) {
        _beacons = [NSMutableDictionary new];
    }
    return _beacons;
}

#pragma mark NSTableView

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.beacons.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    // get an existing cell with the MyView identifier if it exists
    NSTextField *result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
    
    // There is no existing cell to reuse so we will create a new one
    if (result == nil) {
        
        result = [[NSTextField alloc] initWithFrame:CGRectZero];
        [result setBordered:NO];
        [result setBackgroundColor:[NSColor clearColor]];
        [result setIdentifier:@"MyView"];
        [result setEditable:NO];
    }
    
    NSDictionary *beacon = [[self.beacons allValues] objectAtIndex:row];
    if ([tableColumn.identifier isEqualToString:@"uuid"])
        result.stringValue = [[beacon objectForKey:@"uuid"] UUIDString];
    
    if ([tableColumn.identifier isEqualToString:@"major"])
        result.stringValue = [[beacon objectForKey:@"major"] stringValue];
    
    if ([tableColumn.identifier isEqualToString:@"minor"])
        result.stringValue = [[beacon objectForKey:@"minor"] stringValue];
    
    if ([tableColumn.identifier isEqualToString:@"power"])
        result.stringValue = [[beacon objectForKey:@"power"] stringValue];
    
    if ([tableColumn.identifier isEqualToString:@"rssi"])
        result.stringValue = [[beacon objectForKey:@"RSSI"] stringValue];
    
    
    
    // return the result.
    return result;
    
}


@end
