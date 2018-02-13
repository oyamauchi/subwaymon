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

@implementation SubwayMonView

- (void)initialize {
  // Set up 8 long-lived TrainViews at start time, and keep updating them as time goes on
  _trainViews = [[NSMutableArray alloc] initWithCapacity:8];

  float rowHeight = self.frame.size.height / 8;
  float padding = 0.1 * rowHeight;

  for (int i = 0; i < 8; ++i) {
    float y = self.frame.size.height - ((i + 1) * rowHeight) + padding;
    float height = rowHeight - padding * 2;
    TrainView* train = [[TrainView alloc] initWithFrame:NSMakeRect(padding, y,
                                                                   self.frame.size.width - 2*padding,
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

  [self sendRequest];
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

@end
