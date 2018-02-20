//
//  SubwayMonView.m
//  SubwayMon
//
//  Created by Owen Yamauchi on 2/12/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

#import "SubwayMonView.h"

#import <sstream>

#import "TrainView.h"
#import "backend.h"
#import "csv-parser.h"

@implementation SubwayMonView

- (void)setSubviewSizes {
  float rowHeight = self.frame.size.height / 8;
  float padding = 0.1 * rowHeight;

  for (int i = 0; i < 8; ++i) {
    float y = self.frame.size.height - ((i + 1) * rowHeight) + padding;
    float height = rowHeight - padding * 2;
    [[_trainViews objectAtIndex:i] setFrame:NSMakeRect(padding, y,
                                                       self.frame.size.width - 2*padding,
                                                       height)];
  }
}

- (void)initialize:(NSInteger)stationTag {
  // Set up 8 long-lived TrainViews at start time, and keep updating them as time goes on
  _trainViews = [[NSMutableArray alloc] initWithCapacity:8];

  for (int i = 0; i < 8; ++i) {
    TrainView* train = [[TrainView alloc] initWithFrame:NSZeroRect
                                                 symbol:'X'
                                                  color:LineColorShuttle
                                                  shape:LineShapeCircle
                                                   text:@"Loading..."
                                                minutes:1];
    [train setHidden:YES];
    [self addSubview:train];
    [_trainViews addObject:train];
  }

  [self setSubviewSizes];

  NSString* stopsPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"stops"
                                                                         ofType:@"txt"];
  _gtfsStops = [[NSString alloc] initWithContentsOfFile:stopsPath
                                               encoding:NSUTF8StringEncoding
                                                  error:NULL];

  self.selectedStationTag = stationTag;

  [self sendRequest];
}

//////////////////////////////////////////////////////////////////////////////////
//
#pragma mark Data fetching
//
//////////////////////////////////////////////////////////////////////////////////

- (void)sendRequest {
  if (!_sessionTask) {
    NSString* uri = @"http://subwaymon.nfshost.com/fetch.php";

    _sessionTask = [[NSURLSession sharedSession]
                    dataTaskWithURL:[NSURL URLWithString:uri]
                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                      if (!_feedData) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                          [self setNeedsDisplay:YES];
                        });
                      }

                      self.feedData = data;
                      self.sessionTask = nil;

                      [self performSelector:@selector(sendRequest)
                                 withObject:nil
                                 afterDelay:60.0];
                    }];
    [_sessionTask resume];
  }
}

//////////////////////////////////////////////////////////////////////////////////
//
#pragma mark UI logic
//
//////////////////////////////////////////////////////////////////////////////////

- (void)populateMenu:(NSPopUpButton*)menu {
  auto lines = parseCSV([_gtfsStops UTF8String]);

  // This is pretty heinous engineering. It assumes the stops file is sorted and is going to be a
  // pain to change if we ever get real-time data for more lines. Whatever.
  int section = 0;
  [menu removeAllItems];
  [menu addItemWithTitle:@"Broadway - 7 Av trains"];
  [[menu lastItem] setEnabled:NO];

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
      [[menu menu] addItem:[NSMenuItem separatorItem]];
      [menu addItemWithTitle:@"Lexington Av trains"];
      [[menu lastItem] setEnabled:NO];
      section = 1;
    } else if (stopId[0] == '9' && section == 1) {
      [[menu menu] addItem:[NSMenuItem separatorItem]];
      [menu addItemWithTitle:@"42 St Shuttle"];
      [[menu lastItem] setEnabled:NO];
      section = 2;
    }

    auto const& stopName = line[2];
    [[menu menu] addItemWithTitle:[NSString stringWithUTF8String:stopName.c_str()]
                           action:nil
                    keyEquivalent:@""];
    [[menu lastItem] setTag:atoi(stopId.c_str())];
    [[menu lastItem] setEnabled:YES];
    [[menu lastItem] setIndentationLevel:1];
  }

  [menu selectItemWithTag:[self selectedStationTag]];
}

//////////////////////////////////////////////////////////////////////////////////
//
#pragma mark Drawing logic
//
//////////////////////////////////////////////////////////////////////////////////


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

- (void)drawRect:(NSRect)dirtyRect {
  [[NSColor blackColor] set];
  NSRectFill(dirtyRect);

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
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
  [super resizeSubviewsWithOldSize:oldSize];
  [self setSubviewSizes];
}

@end
