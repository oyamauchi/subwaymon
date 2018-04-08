//
//  LineEnums.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 2/25/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import AppKit

func color(forRoute: String) -> NSColor {
  var r: Int
  var g: Int
  var b: Int
  switch (forRoute) {
  case "1", "2", "3":
    (r, g, b) = (0xEE, 0x35, 0x2E)
  case "4", "5", "5X", "6", "6X":
    (r, g, b) = (0x00, 0x93, 0x3C)
  case "7", "7X":
    (r, g, b) = (0xB9, 0x33, 0xAD)
  case "A", "C", "E", "SI":
    (r, g, b) = (0x00, 0x39, 0xA6)
  case "B", "D", "F", "M":
    (r, g, b) = (0xFF, 0x63, 0x19)
  case "G":
    (r, g, b) = (0x6C, 0xBE, 0x45)
  case "J", "Z":
    (r, g, b) = (0x99, 0x66, 0x33)
  case "L":
    (r, g, b) = (0xA7, 0xA9, 0xAC)
  case "N", "Q", "R", "W":
    (r, g, b) = (0xFC, 0xCC, 0x0A)
  case "FS", "GS", "H":
    (r, g, b) = (0x80, 0x81, 0x83)
  default:
    fatalError("Unknown route \(forRoute)")
  }
  return NSColor(
    calibratedRed: CGFloat(r) / 255.0,
    green: CGFloat(g) / 255.0,
    blue: CGFloat(b) / 255.0,
    alpha: 1.0
  )
}

func char(forRoute: String) -> Character {
  switch (forRoute) {
  case "FS", "GS", "H":
    return "S"
  case "SI":
    return "S"
  case "6X":
    return "6"
  case "7X":
    return "7"
  default:
    return forRoute.first!
  }
}
