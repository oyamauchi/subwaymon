#pragma once

#import <ScreenSaver/ScreenSaver.h>

@interface SubwayMonScreenSaverView : ScreenSaverView <NSURLDownloadDelegate>
{
  // I'd rather save the parsed form -- i.e. std::vector<std::vector<std::string>> --
  // but dealing with C++ members of Objective-C objects doesn't sound like fun.
  NSString* _gtfsStops;

  NSMutableArray* _trainViews;
  NSData* _feedData;

  NSURLDownload* _urlDownload;
  NSString* _dataDownloadPath;

  NSArray* _topLevelObjects;
  IBOutlet NSWindow* _configSheet;
  IBOutlet NSPopUpButton* _menu;
}

@property(nonatomic, retain) NSString* gtfsStops;
@property(nonatomic, retain) NSArray* trainViews;
@property(nonatomic, retain) NSData* feedData;
@property(nonatomic, retain) NSURLDownload* urlDownload;
@property(nonatomic, copy) NSString* dataDownloadPath;

- (IBAction)closeSheet:(id)sender;

@end
