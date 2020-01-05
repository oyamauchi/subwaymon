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
  var color: NSColor = NSColor.white
  var isDiamond: Bool = false
  var isBlackText: Bool = false
  var text: String = ""
  var minutes: Int = 0

  /// First try cutting the string at the hyphens, until it fits in the available width.
  /// If that doesn't work, truncate and ellipsize the string until it fits.
  private func truncate(text: String,
                        withAttributes attributes:[NSAttributedString.Key: Any],
                        toWidth width: CGFloat) -> String {
    let fields = text.components(separatedBy: " - ")

    var lastField = fields.endIndex

    while (lastField > fields.startIndex) {
      let attempt = fields[fields.startIndex..<lastField].joined(separator: " - ")

      if (attempt.size(withAttributes: attributes).width <= width) {
        return attempt
      }

      lastField = lastField.advanced(by: -1)
    }

    var attempt = fields[0]

    while (attempt.size(withAttributes: attributes).width > width && attempt.count > 1) {
      let range = attempt.index(attempt.endIndex, offsetBy: -2)..<attempt.endIndex
      attempt = attempt.replacingCharacters(in: range, with: "\u{2026}")
    }

    return attempt
  }

  private func getTextAttributes(size: CGFloat, color: NSColor) -> [NSAttributedString.Key: Any] {
    return [
      NSAttributedString.Key.foregroundColor: color,
      NSAttributedString.Key.font: NSFont(name: "Helvetica Bold", size: size) as Any
    ]
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor.black.set()
    dirtyRect.fill()

    self.color.set()

    // These values will be used for all the text
    let fontSize = 0.84 * self.bounds.size.height
    let giantWhiteText = getTextAttributes(size: fontSize, color: NSColor.white)

    // Draw the route bullet. It should be a square that fills the height of this view,
    // left-aligned. First draw the shape.
    let shapeRect = NSMakeRect(0, 0, self.bounds.size.height, self.bounds.size.height)

    if (self.isDiamond) {
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

    if (isBlackText) {
      symStr.draw(at: NSMakePoint(x, y),
                  withAttributes: getTextAttributes(size: fontSize, color: NSColor.black))
    } else {
      symStr.draw(at: NSMakePoint(x, y), withAttributes: giantWhiteText)
    }

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
