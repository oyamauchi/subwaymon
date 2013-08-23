
#import "SubwayMonView.h"

#import <cstdlib>
#import <sstream>
#import <string>

#import "backend.h"
#import "csv-parser.h"
#import "TrainView.h"

static NSString* kSelectedStationKey = @"SelectedStation";

@implementation SubwayMonView

- (IBAction)closeSheet:(id)sender {
  ScreenSaverDefaults* defaults =
    [ScreenSaverDefaults defaultsForModuleWithName:@"com.oyamauchi.SubwayMon"];
  [defaults setInteger:_menu.selectedTag forKey:kSelectedStationKey];
  [defaults synchronize];

  [[NSApplication sharedApplication] endSheet:_configSheet];
}

- (ELineColor)lineColorForSymbol:(const char)sym {
  switch (sym) {
    case '1': case '2': case '3':
      return LineColorBwaySeventh;
    case '4': case '5': case '6':
      return LineColorLexington;
    case 'S':
      return LineColorShuttle;
  }
  return LineColorShuttle;
}

- (void)updateViews:(const std::vector<Arrival>&)arrs top:(BOOL)top {
  int offset = (top ? 0 : 4);
  int i = 0;

  for (; i < 4 && i < arrs.size(); ++i) {
    TrainView* tv = _trainViews[i + offset];

    auto const& arr = arrs[i];
    const char symbol = (arr.train == "6X" ? '6'
                         : arr.train == "GS" ? 'S'
                         : arr.train[0]);
    const ELineShape shape = (arr.train == "6X" ? LineShapeDiamond : LineShapeCircle);
    const ELineColor color = [self lineColorForSymbol:symbol];
    NSString* dest = [NSString stringWithCString:arr.destination.c_str()
                                        encoding:NSUTF8StringEncoding];

    tv.symbol = symbol;
    tv.shape = shape;
    tv.color = color;
    tv.text = dest;
    tv.minutes = (arr.seconds + 29) / 60;  // round to nearest minute

    [tv setHidden:NO];
    [tv setNeedsDisplay:YES];
  }

  for (; i < 4; ++i) {
    [_trainViews[i + offset] setHidden:YES];
  }
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

    // Set up 8 long-lived TrainViews at start time, and keep updating them as time goes on
    _trainViews = [[NSMutableArray alloc] initWithCapacity:8];

    float rowHeight = frame.size.height / 8;
    float padding = 0.1 * rowHeight;

    for (int i = 0; i < 8; ++i) {
      float y = frame.size.height - ((i + 1) * rowHeight) + padding;
      float height = rowHeight - padding * 2;
      TrainView* train = [[TrainView alloc] initWithFrame:NSMakeRect(padding, y,
                                                                     frame.size.width - 2*padding,
                                                                     height)
                                                   symbol:'X'
                                                    color:LineColorShuttle
                                                    shape:LineShapeCircle
                                                     text:@"Loading..."
                                                  minutes:1];
      [train setHidden:YES];
      [self addSubview:train];
      [_trainViews addObject:train];
      [train release];
    }

    NSString* stopsPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"stops"
                                                                           ofType:@"txt"];
    self.gtfsStops = [NSString stringWithContentsOfFile:stopsPath
                                               encoding:NSUTF8StringEncoding
                                                  error:NULL];

    [self sendRequest];
  }
  return self;
}

- (void)dealloc {
  [_gtfsStops release];
  [_trainViews release];
  [_feedData release];
  [_urlDownload release];
  [_dataDownloadPath release];
  [_topLevelObjects release];
  [super dealloc];
}

- (void)sendRequest {
  if (!_urlDownload) {
    NSString* uri = @"http://subwaymon.nfshost.com/fetch.php";
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:uri]];
    self.urlDownload = [[[NSURLDownload alloc] initWithRequest:req delegate:self] autorelease];
  }
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path {
  self.dataDownloadPath = path;
}

- (void)downloadDidFinish:(NSURLDownload *)download {
  if (!_feedData) {
    // If this is the first update, force an immediate redraw
    [self setNeedsDisplay:YES];
  }

  // This will be picked up by the next redraw
  self.feedData = [NSData dataWithContentsOfFile:self.dataDownloadPath];

  self.urlDownload = nil;
  self.dataDownloadPath = nil;

  // Schedule the next refresh to be done in one minute
  [self performSelector:@selector(sendRequest)
             withObject:nil
             afterDelay:60.0];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
  [self performSelector:@selector(sendRequest)
             withObject:nil
             afterDelay:60.0];
}

- (void)drawRect:(NSRect)rect {
  [[NSColor blackColor] set];
  NSRectFill(rect);

  if (!_feedData) {
    return;
  }

  // Read the arrivals twice: once for the northbound direction of our stop id and once for the
  // southbound. The GS shuttle considers TS to be north and GC to be south.
  std::ostringstream oss;
  oss << [self selectedStationTag];

  std::string feedData(static_cast<const char*>([_feedData bytes]), [_feedData length]);
  auto arrs = arrivalsAt(oss.str() + "N", feedData, [_gtfsStops UTF8String]);
  [self updateViews:arrs top:YES];
  arrs = arrivalsAt(oss.str() + "S", feedData, [_gtfsStops UTF8String]);
  [self updateViews:arrs top:NO];

  // Draw the separator between the two halves
  NSBezierPath* line = [NSBezierPath bezierPath];
  [line moveToPoint:NSMakePoint(0, self.bounds.size.height / 2)];
  [line lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height / 2)];
  [line setLineWidth:2.5];
  [[NSColor whiteColor] set];
  [line stroke];
  return;
}

- (void)animateOneFrame {
  [self setNeedsDisplay:YES];
}

- (BOOL)hasConfigureSheet {
  return YES;
}

- (NSWindow*)configureSheet {
  if (!_configSheet) {
    [[NSBundle bundleForClass:[self class]] loadNibNamed:@"ConfigureSheet"
                                                   owner:self
                                         topLevelObjects:&_topLevelObjects];
    [_topLevelObjects retain];

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
