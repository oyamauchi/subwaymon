//
//  SubwayMonView.h
//  SubwayMon
//
//  Created by Owen Yamauchi on 2/12/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SubwayMonView : NSView <NSURLDownloadDelegate> {
  // I'd rather save the parsed form -- i.e. std::vector<std::vector<std::string>> --
  // but dealing with C++ members of Objective-C objects doesn't sound like fun.
  NSString* _gtfsStops;

  NSMutableArray* _trainViews;
  NSData* _feedData;

  NSURLDownload* _urlDownload;
  NSString* _dataDownloadPath;
  NSInteger _selectedStationTag;
}

@property(nonatomic, strong) NSString* gtfsStops;
@property(nonatomic, strong) NSArray* trainViews;
@property(nonatomic, strong) NSData* feedData;
@property(nonatomic, strong) NSURLDownload* urlDownload;
@property(nonatomic, copy) NSString* dataDownloadPath;
@property(nonatomic, assign) NSInteger selectedStationTag;

- (void)initialize;

@end
