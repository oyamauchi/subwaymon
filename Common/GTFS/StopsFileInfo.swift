//
//  StopsFileInfo.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/10/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import AppKit

class StopsFileInfo {
  static let shared = StopsFileInfo()

  private var gtfsStops: Array<Array<String>>!
  private var idToName = Dictionary<StopId, String>()
  private var tagToId = Dictionary<Int, StopId>()
  private var idToTag = Dictionary<StopId, Int>()

  private(set) var menu: NSMenu!

  private init() {
    let stopsPath = Bundle(for: SubwayMonView.self).path(forResource: "stops", ofType: "txt")!
    let rawGtfsStops = try? String.init(contentsOfFile: stopsPath)

    gtfsStops = parseCsv(rawGtfsStops!)

    var tag = 1

    for line in gtfsStops {
      if line.isEmpty || line.first == "stop_id" {
        continue
      }
      idToName[line[0]] = line[2]
      tagToId[tag] = line[0]
      idToTag[line[0]] = tag

      tag += 1
    }

    populateMenu()
  }

  func name(ofStopId stopId: StopId) -> String {
    return idToName[stopId]!
  }

  func stopId(forTag tag: Int) -> StopId {
    return tagToId[tag]!
  }

  func tag(forStopId stopId: StopId) -> Int {
    return idToTag[stopId]!
  }

  private func populateMenu() {
    menu = NSMenu()
    menu.autoenablesItems = false

    // This is pretty heinous engineering. It assumes the stops file is sorted and is going to be a
    // pain to change if we ever get real-time data for more lines. Whatever.
    var section = 0
    menu.addItem(withTitle: "Broadway - 7 Av trains", action: nil, keyEquivalent: "")
    menu.items.last!.isEnabled = false

    for line in gtfsStops {
      let stopId = line[0]
      let first = stopId.first!

      // We don't want the directional stop ids (like 631N), or the ones for the B Division, or
      // the ones for the Flushing line (i.e. 7 train).
      if stopId.count != 3 || first < "1" || first > "9" || first == "7" {
        continue
      }

      // If we're seeing 4xx stops (i.e. 4 train stops) for the first time, or a 9xx stop (the GS
      // shuttle), start a new section.
      if first == "4" && section == 0 {
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Lexington Av trains", action: nil, keyEquivalent: "")
        menu.items.last!.isEnabled = false
        section = 1
      } else if first == "9" && section == 1 {
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "42 St Shuttle", action: nil, keyEquivalent: "")
        menu.items.last!.isEnabled = false
        section = 2
      }

      let item = NSMenuItem(title: line[2], action: nil, keyEquivalent: "")
      item.tag = idToTag[stopId]!
      item.isEnabled = true
      item.indentationLevel = 1
      menu.addItem(item)
    }
  }
}
