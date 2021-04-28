// TrainView.swift
// Copyright 2021 Owen Yamauchi

import AppKit

class TrainView: NSView {
  var symbol: RouteSymbol!
  var text: String = ""
  var minutes: Int = 0

  /// First try cutting the string at the hyphens, until it fits in the available width.
  /// If that doesn't work, truncate and ellipsize the string until it fits.
  private func truncate(
    text: String,
    withAttributes attributes: [NSAttributedString.Key: Any],
    toWidth width: CGFloat
  ) -> String {
    let fields = text.components(separatedBy: "-")

    var firstField = fields.startIndex

    while firstField < fields.endIndex {
      let attempt = fields[firstField ..< fields.endIndex].joined(separator: "-")

      if attempt.size(withAttributes: attributes).width <= width {
        return attempt
      }

      firstField = firstField.advanced(by: 1)
    }

    var attempt = fields[0]

    while attempt.size(withAttributes: attributes).width > width, attempt.count > 1 {
      let range = attempt.index(attempt.endIndex, offsetBy: -2) ..< attempt.endIndex
      attempt = attempt.replacingCharacters(in: range, with: "\u{2026}")
    }

    return attempt
  }

  private func getTextAttributes(size: CGFloat, color: NSColor) -> [NSAttributedString.Key: Any] {
    return [
      NSAttributedString.Key.foregroundColor: color,
      NSAttributedString.Key.font: NSFont(name: "Helvetica Bold", size: size) as Any,
    ]
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor.black.set()
    dirtyRect.fill()

    if symbol == nil {
      return
    }

    symbol.color.set()

    // Draw the route bullet. It should be a square that fills the height of this view,
    // left-aligned. First draw the shape.
    let shapeRect = NSMakeRect(0, 0, bounds.size.height, bounds.size.height)

    switch symbol.shape {
    case .diamond:
      let shape = NSBezierPath()
      shape.move(to: NSMakePoint(shapeRect.size.width / 2, 0))
      shape.line(to: NSMakePoint(shapeRect.size.width, shapeRect.size.height / 2))
      shape.line(to: NSMakePoint(shapeRect.size.width / 2, shapeRect.size.height))
      shape.line(to: NSMakePoint(0, shapeRect.size.height / 2))
      shape.close()
      shape.fill()
    case .circle:
      let bullet = NSBezierPath(ovalIn: shapeRect)
      bullet.fill()
    }

    // Now draw the symbol
    let symbolFontSize: CGFloat
    switch symbol.text.count {
    case 1: symbolFontSize = 0.84 * bounds.size.height
    case 2: symbolFontSize = 0.55 * bounds.size.height
    case 3: symbolFontSize = 0.46 * bounds.size.height
    default: symbolFontSize = 0.4 * bounds.size.height
    }

    let symbolAttributes = getTextAttributes(size: symbolFontSize, color: symbol.textColor)
    let textSize = symbol.text.size(withAttributes: symbolAttributes)

    let symbolPoint = NSMakePoint(
      (shapeRect.size.width - textSize.width) / 2 + shapeRect.origin.x,
      (shapeRect.size.height - textSize.height) / 2 + shapeRect.origin.y
    )

    symbol.text.draw(at: symbolPoint, withAttributes: symbolAttributes)

    // These values will be used for the rest of the text
    let baseFontSize = 0.84 * bounds.size.height
    let giantWhiteText = getTextAttributes(size: baseFontSize, color: NSColor.white)

    // Draw the time remaining. It's simple text.
    let minString = "\(minutes) min"
    let minSize = minString.size(withAttributes: giantWhiteText)
    let minY = (bounds.size.height - minSize.height) / 2
    let minOrigin = NSMakePoint(bounds.size.width - minSize.width, minY)

    minString.draw(at: minOrigin, withAttributes: giantWhiteText)

    let leftPadding = shapeRect.size.width * 0.2
    let rightPadding = shapeRect.size.width * 0.5

    let availableWidth =
      bounds.size.width - shapeRect.size.width - leftPadding - rightPadding - minSize.width
    let destString =
      truncate(text: text, withAttributes: giantWhiteText, toWidth: availableWidth)
    let textOrigin = NSMakePoint(shapeRect.size.width + leftPadding, minY)
    destString.draw(at: textOrigin, withAttributes: giantWhiteText)
  }
}
