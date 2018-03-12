//
//  LineEnums.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 2/25/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import Foundation

enum LineColor {
  case Lexington
  case BwaySeventh
  case Shuttle

  static func forSymbol(_ symbol: Character) -> LineColor {
    switch (symbol) {
    case "1", "2", "3":
      return .BwaySeventh
    case "4", "5", "6":
      return .Lexington
    case "S":
      return .Shuttle
    default:
      fatalError("Unknown line symbol \(symbol)")
    }
  }
}

enum LineShape {
  case Circle
  case Diamond
}
