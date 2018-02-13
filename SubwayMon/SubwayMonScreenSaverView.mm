
#import "SubwayMonScreenSaverView.h"

#import "csv-parser.h"

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
    _gtfsStops = _subwayView.gtfsStops;
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

    auto lines = parseCSV([_gtfsStops UTF8String]);

    // This is pretty heinous engineering. It assumes the stops file is sorted and is going to be a
    // pain to change if we ever get real-time data for more lines. Whatever.
    int section = 0;
    [_menu removeAllItems];
    [_menu addItemWithTitle:@"Broadway - 7 Av trains"];
    [[_menu lastItem] setEnabled:NO];

    for (auto const& line : lines) {
      if (line.size() < 3) {
        continue;
      }

      auto const& stopId = line[0];
      if (stopId.size() != 3 ||
          stopId[0] < '1' || stopId[0] > '9' || stopId[0] == '7') {
        // We don't want the directional stop ids (like 631N), or the ones for the B Division, or
        // the ones for the Flushing line (i.e. 7 train).
        continue;
      }

      // If we're seeing 4xx stops (i.e. 4 train stops) for the first time, or a 9xx stop (the GS
      // shuttle), start a new section.
      if (stopId[0] == '4' && section == 0) {
        [[_menu menu] addItem:[NSMenuItem separatorItem]];
        [_menu addItemWithTitle:@"Lexington Av trains"];
        [[_menu lastItem] setEnabled:NO];
        section = 1;
      } else if (stopId[0] == '9' && section == 1) {
        [[_menu menu] addItem:[NSMenuItem separatorItem]];
        [_menu addItemWithTitle:@"42 St Shuttle"];
        [[_menu lastItem] setEnabled:NO];
        section = 2;
      }

      auto const& stopName = line[2];
      [[_menu menu] addItemWithTitle:[NSString stringWithUTF8String:stopName.c_str()]
                              action:nil
                       keyEquivalent:@""];
      [[_menu lastItem] setTag:atoi(stopId.c_str())];
      [[_menu lastItem] setEnabled:YES];
      [[_menu lastItem] setIndentationLevel:1];
    }
  }

  [_menu selectItemWithTag:[self selectedStationTag]];

  return _configSheet;
}

@end
