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

  private var groups = Dictionary<String, Array<StopId>>()

  private var idToName = Dictionary<StopId, String>()
  private var idToFeeds = Dictionary<StopId, Array<Int>>()

  private var tagToId = Dictionary<Int, StopId>()
  private var idToTag = Dictionary<StopId, Int>()

  private(set) var menu: NSMenu!

  private init() {
    let path = Bundle(for: SubwayMonView.self).path(forResource: "feedinfo", ofType: "json")!
    let stream = InputStream(fileAtPath: path)!
    stream.open()

    let feedInfoRaw = try? JSONSerialization.jsonObject(with: stream,
                                                        options: JSONSerialization.ReadingOptions())
    let feedInfo = feedInfoRaw as! Dictionary<String, Any>
    let stopInfo = feedInfo["stopinfo"] as! Dictionary<StopId, Dictionary<String, Any>>

    groups = feedInfo["groups"] as! Dictionary<String, Array<StopId>>

    var tag = 1
    for (stopId, infoDict) in stopInfo {
      idToName[stopId] = (infoDict["name"] as! String)
      idToFeeds[stopId] = (infoDict["feeds"] as! Array<Int>)

      tagToId[tag] = stopId
      idToTag[stopId] = tag

      tag += 1
    }

    populateMenu()
  }

  func name(ofStopId stopId: StopId) -> String {
    return idToName[trim(stopId: stopId)]!
  }

  func feeds(forStopId stopId: StopId) -> Array<Int> {
    return idToFeeds[trim(stopId: stopId)]!
  }

  func stopId(forTag tag: Int) -> StopId {
    return tagToId[tag]!
  }

  func tag(forStopId stopId: StopId) -> Int {
    return idToTag[trim(stopId: stopId)]!
  }

  private func trim(stopId: StopId) -> StopId {
    return stopId.substring(to: stopId.index(stopId.startIndex, offsetBy: 3))
  }

  private func populateMenu() {
    menu = NSMenu()
    menu.autoenablesItems = false

    for (section, group) in groups {
      if menu.items.count > 0 {
        menu.addItem(NSMenuItem.separator())
      }

      menu.addItem(withTitle: section, action: nil, keyEquivalent: "")
      menu.items.last!.isEnabled = false

      for stopId in group {
        let item = NSMenuItem(title: idToName[stopId]!, action: nil, keyEquivalent: "")
        item.tag = idToTag[stopId]!
        item.isEnabled = true
        item.indentationLevel = 1
        menu.addItem(item)
      }
    }
  }
}
