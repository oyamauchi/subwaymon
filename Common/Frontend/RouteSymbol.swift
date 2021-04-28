//
//  RouteSymbol.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 12/11/20.
//  Copyright © 2020 Owen Yamauchi. All rights reserved.
//

import AppKit

struct RouteSymbol {
  enum Shape: String {
    case circle
    case diamond
  }

  let text: String
  let textColor: NSColor
  let shape: Shape
  let color: NSColor

  static func colorFrom(hexString: String) -> NSColor {
    let r = Int(hexString.prefix(2), radix: 16)!
    let g = Int(hexString.prefix(4).suffix(2), radix: 16)!
    let b = Int(hexString.suffix(2), radix: 16)!
    return NSColor(
      red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0)
  }
}
