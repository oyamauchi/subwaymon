
#import "TrainView.h"

@implementation TrainView

- (id)initWithFrame:(NSRect)frame
             symbol:(char)symbol
              color:(ELineColor)color
              shape:(ELineShape)shape
               text:(NSString*)text
            minutes:(int64_t)minutes {
  self = [super initWithFrame:frame];
  if (self) {
    _symbol = symbol;
    _color = color;
    _shape = shape;
    self.text = text;
    _minutes = minutes;
  }
  return self;
}

- (void)dealloc {
  [_text release];
  [super dealloc];
}

- (NSString*)truncateText:(NSString*)text
           withAttributes:(NSDictionary*)attr
                  toWidth:(float)width {
  NSString* attempt = text;

  while ([attempt sizeWithAttributes:attr].width > width && [attempt length] > 1) {
    NSUInteger loc = [attempt length] - 2;
    attempt = [attempt stringByReplacingCharactersInRange:NSMakeRange(loc, 2)
                                               withString:@"\u2026"];
  }

  return attempt;
}

- (void)drawRect:(NSRect)dirtyRect
{
  // Background fill
  [[NSColor blackColor] set];
  NSRectFill(dirtyRect);

  NSColor* bulletColor = nil;

  switch (_color) {
    case LineColorLexington:
      bulletColor = [NSColor colorWithCalibratedRed:0
                                              green:((float)0x93 / 0xff)
                                               blue:((float)0x3c / 0xff)
                                              alpha:1.0];
      break;
    case LineColorBwaySeventh:
      bulletColor = [NSColor colorWithCalibratedRed:((float)0xee / 0xff)
                                              green:((float)0x35 / 0xff)
                                               blue:((float)0x23 / 0xff)
                                              alpha:1.0];
      break;
    case LineColorShuttle:
      bulletColor = [NSColor colorWithCalibratedRed:((float)0x80 / 0xff)
                                              green:((float)0x81 / 0xff)
                                               blue:((float)0x83 / 0xff)
                                              alpha:1.0];
      break;
  }

  [bulletColor set];

  NSRect shapeRect = NSMakeRect(0, 0, self.bounds.size.height, self.bounds.size.height);

  if (_shape == LineShapeDiamond) {
    NSBezierPath* shape = [NSBezierPath bezierPath];
    [shape moveToPoint:NSMakePoint(shapeRect.size.width / 2, 0)];
    [shape lineToPoint:NSMakePoint(shapeRect.size.width, shapeRect.size.height / 2)];
    [shape lineToPoint:NSMakePoint(shapeRect.size.width / 2, shapeRect.size.height)];
    [shape lineToPoint:NSMakePoint(0, shapeRect.size.height / 2)];
    [shape closePath];
    [shape fill];
  } else {
    NSBezierPath* bullet = [NSBezierPath bezierPathWithOvalInRect:shapeRect];
    [bullet fill];
  }

  // Now draw the symbol
  NSString* symbol = [NSString stringWithCharacters:(const unichar*)&_symbol length:1];
  float fontSize = (84.0 / 100) * shapeRect.size.height;
  NSDictionary* giantWhiteAttr =
  @{NSForegroundColorAttributeName: [NSColor whiteColor],
    NSFontAttributeName: [NSFont fontWithName:@"Helvetica Bold" size:fontSize]};
  NSSize textSize = [symbol sizeWithAttributes:giantWhiteAttr];
  float x = (shapeRect.size.width - textSize.width) / 2 + shapeRect.origin.x;
  float y = (shapeRect.size.height - textSize.height) / 2 + shapeRect.origin.y;
  [symbol drawAtPoint:NSMakePoint(x, y) withAttributes:giantWhiteAttr];

  // Time remaining
  NSString* minString = [NSString stringWithFormat:@"%lld min", _minutes];
  NSSize minSize = [minString sizeWithAttributes:giantWhiteAttr];
  NSPoint minOrigin = NSMakePoint(self.bounds.size.width - minSize.width, y);
  [minString drawAtPoint:minOrigin withAttributes:giantWhiteAttr];

  // Destination. It's constrained between the bullet on the left and the minutes on the right.
  float leftPadding = shapeRect.size.width * 0.2;
  float rightPadding = shapeRect.size.width * 0.5;
  float availableWidth = self.bounds.size.width - shapeRect.size.width - leftPadding - rightPadding - minSize.width;
  NSString* destString = [self truncateText:_text withAttributes:giantWhiteAttr toWidth:availableWidth];
  NSPoint textOrigin = NSMakePoint(shapeRect.size.width + leftPadding, y);
  [destString drawAtPoint:textOrigin withAttributes:giantWhiteAttr];
}

@end
