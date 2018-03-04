
#import "SubwayMonScreenSaverView.h"

static NSString* kSelectedStationKey = @"SelectedStation";

@implementation SubwayMonScreenSaverView

- (IBAction)closeSheet:(id)sender {
  ScreenSaverDefaults* defaults =
    [ScreenSaverDefaults defaultsForModuleWithName:@"com.oyamauchi.SubwayMon"];
  [defaults setInteger:_menu.selectedTag forKey:kSelectedStationKey];
  [defaults synchronize];

  [_subwayView setSelectedStationTag:_menu.selectedTag];

  [[NSApplication sharedApplication] endSheet:_configSheet];
}

- (NSInteger)selectedStationTag {
  ScreenSaverDefaults* defaults =
    [ScreenSaverDefaults defaultsForModuleWithName:@"com.oyamauchi.SubwayMon"];
  // Grand Central on the Lex by default
  return [defaults integerForKey:kSelectedStationKey] ?: 631;
}


- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
  self = [super initWithFrame:frame isPreview:isPreview];
  if (self) {
    [self setAnimationTimeInterval:5.0];

    _subwayView = [[SubwayMonView alloc] initWithFrame:self.bounds];
    [_subwayView initialize:[self selectedStationTag]];
    [self addSubview:_subwayView];
  }
  return self;
}


- (void)animateOneFrame {
  [self setNeedsDisplay:YES];
}

- (BOOL)hasConfigureSheet {
  return YES;
}

- (NSWindow*)configureSheet {
  if (!_configSheet) {
    NSArray* topLevelObjects;
    [[NSBundle bundleForClass:[self class]] loadNibNamed:@"ConfigureSheet"
                                                   owner:self
                                         topLevelObjects:&topLevelObjects];
    _topLevelObjects = topLevelObjects;

    [_subwayView populateMenu:_menu];
  }

  return _configSheet;
}

@end
