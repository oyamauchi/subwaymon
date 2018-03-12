//
//  TrainView.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 2/25/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import AppKit

class TrainView: NSView {

  var symbol: Character = "X"
  var color: LineColor = .Shuttle
  var shape: LineShape = .Circle
  var text: String = ""
  var minutes: Int = 0

  private func truncate(text: String,
                        withAttributes attributes: Dictionary<String, Any>,
                        toWidth width: CGFloat) -> String {
    var attempt = text

    while (attempt.size(withAttributes: attributes).width > width && attempt.count > 1) {
      let range = attempt.index(attempt.endIndex, offsetBy: -2)..<attempt.endIndex
      attempt = attempt.replacingCharacters(in: range, with: "\u{2026}")
    }

    return attempt
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor.black.set()
    NSRectFill(dirtyRect)

    var bulletColor: NSColor

    switch self.color {
    case .BwaySeventh:
      bulletColor =
        NSColor(calibratedRed: 0xEE / 255.0, green: 0x35 / 255.0, blue: 0x23 / 255.0, alpha: 1.0)
    case .Lexington:
      bulletColor =
        NSColor(calibratedRed: 0, green: 0x93 / 255.0, blue: 0x3C / 255.0, alpha: 1.0)
    case .Shuttle:
      bulletColor =
        NSColor(calibratedRed: 0x80 / 255.0, green: 0x81 / 255.0, blue: 0x83 / 255.0, alpha: 1.0)
    }

    bulletColor.set()

    // These values will be used for all the text
    let fontSize = 0.84 * self.bounds.size.height
    let giantWhiteText: Dictionary<String, Any> = [
      NSForegroundColorAttributeName: NSColor.white,
      NSFontAttributeName: NSFont(name: "Helvetica Bold", size: fontSize) as Any
    ]

    // Draw the route bullet. It should be a square that fills the height of this view,
    // left-aligned. First draw the shape.
    let shapeRect = NSMakeRect(0, 0, self.bounds.size.height, self.bounds.size.height)

    if (shape == .Diamond) {
      let shape = NSBezierPath()
      shape.move(to: NSMakePoint(shapeRect.size.width / 2, 0))
      shape.line(to: NSMakePoint(shapeRect.size.width, shapeRect.size.height / 2))
      shape.line(to: NSMakePoint(shapeRect.size.width / 2, shapeRect.size.height))
      shape.line(to: NSMakePoint(0, shapeRect.size.height / 2))
      shape.close()
      shape.fill()
    } else {
      let bullet = NSBezierPath(ovalIn: shapeRect)
      bullet.fill()
    }

    // Now draw the symbol
    let symStr = String(symbol)
    let textSize = symStr.size(withAttributes: giantWhiteText)

    let x = (shapeRect.size.width - textSize.width) / 2 + shapeRect.origin.x
    let y = (shapeRect.size.height - textSize.height) / 2 + shapeRect.origin.y
    symStr.draw(at: NSMakePoint(x, y), withAttributes: giantWhiteText)

    // Draw the time remaining. It's simple text.
    let minString = "\(self.minutes) min"
    let minSize = minString.size(withAttributes: giantWhiteText)
    let minOrigin = NSMakePoint(self.bounds.size.width - minSize.width, y)

    minString.draw(at: minOrigin, withAttributes: giantWhiteText)

    let leftPadding = shapeRect.size.width * 0.2
    let rightPadding = shapeRect.size.width * 0.5

    let availableWidth =
      self.bounds.size.width - shapeRect.size.width - leftPadding - rightPadding - minSize.width
    let destString =
      self.truncate(text: self.text, withAttributes: giantWhiteText, toWidth: availableWidth)
    let textOrigin = NSMakePoint(shapeRect.size.width + leftPadding, y)
    destString.draw(at: textOrigin, withAttributes: giantWhiteText)
  }
}
