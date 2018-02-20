#pragma once

#import <ScreenSaver/ScreenSaver.h>

#import "SubwayMonView.h"

@interface SubwayMonScreenSaverView : ScreenSaverView
{
  NSArray* _topLevelObjects;
  IBOutlet NSWindow* _configSheet;
  IBOutlet NSPopUpButton* _menu;
  IBOutlet SubwayMonView* _subwayView;
}

- (IBAction)closeSheet:(id)sender;

@end
