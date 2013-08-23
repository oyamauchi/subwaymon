#pragma once

#import <Cocoa/Cocoa.h>

typedef enum {
  LineColorLexington,
  LineColorBwaySeventh,
  LineColorShuttle,
} ELineColor;

typedef enum {
  LineShapeCircle,
  LineShapeDiamond,
} ELineShape;

@interface TrainView : NSView
{
  char _symbol;
  ELineColor _color;
  ELineShape _shape;
  NSString* _text;
  int64_t _minutes;
}

@property(nonatomic, assign) char symbol;
@property(nonatomic, assign) ELineColor color;
@property(nonatomic, assign) ELineShape shape;
@property(nonatomic, copy) NSString* text;
@property(nonatomic, assign) int64_t minutes;

- (id)initWithFrame:(NSRect)frame
             symbol:(char)symbol
              color:(ELineColor)color
              shape:(ELineShape)shape
               text:(NSString*)text
            minutes:(int64_t)minutes;

@end
