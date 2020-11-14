//
//  StopsFileInfo.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/10/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import AppKit

class FeedInfo {
  static let providers = ["mta-subway"]
  static let providerMenu = createProviderMenu()

  private static func createProviderMenu() -> NSMenu {
    var index = 0
    let menu = NSMenu()
    menu.autoenablesItems = false

    for provider in providers {
      let item = NSMenuItem(title: provider, action: nil, keyEquivalent: "")
      item.isEnabled = true
      item.tag = index
      index += 1
      menu.addItem(item)
    }

    return menu
  }

  private var groupTagToGroupName = [Int: String]()
  private var groups = [String: [StopId]]()

  private var idToName = [StopId: String]()
  private var idToFeeds = [StopId: [Int]]()

  private var tagToId = [Int: StopId]()
  private var idToTag = [StopId: Int]()

  private(set) var stopGroupMenu: NSMenu!

  init(providerTag: Int) {
    let path = Bundle(for: SubwayMonView.self).path(forResource: FeedInfo.providers[providerTag],
                                                    ofType: "json")!
    let stream = InputStream(fileAtPath: path)!
    stream.open()

    let feedInfoRaw = try? JSONSerialization.jsonObject(with: stream,
                                                        options: JSONSerialization.ReadingOptions())
    let feedInfo = feedInfoRaw as! [String: Any]
    let stopInfo = feedInfo["stopinfo"] as! [StopId: [String: Any]]

    groups = feedInfo["groups"] as! [String: [StopId]]

    var tag = 1
    for (stopId, infoDict) in stopInfo {
      idToName[stopId] = (infoDict["name"] as! String)
      idToFeeds[stopId] = (infoDict["feeds"] as! [Int])

      tagToId[tag] = stopId
      idToTag[stopId] = tag

      tag += 1
    }

    var groupTag = 0
    stopGroupMenu = NSMenu()
    stopGroupMenu.autoenablesItems = false

    for section in groups.keys.sorted() {
      let item = NSMenuItem(title: section, action: nil, keyEquivalent: "")
      item.isEnabled = true
      item.tag = groupTag
      groupTagToGroupName[groupTag] = section

      stopGroupMenu.addItem(item)
      groupTag += 1
    }
  }

  func name(ofStopId stopId: StopId) -> String {
    return idToName[trim(stopId: stopId)]!
  }

  func feeds(forStopId stopId: StopId) -> [Int] {
    return idToFeeds[trim(stopId: stopId)]!
  }

  func stopId(forTag tag: Int) -> StopId {
    return tagToId[tag]!
  }

  func tag(forStopId stopId: StopId) -> Int {
    return idToTag[trim(stopId: stopId)]!
  }

  func stopMenu(forStopGroupTag groupTag: Int) -> NSMenu {
    let groupName = groupTagToGroupName[groupTag]!
    let group = groups[groupName]!

    let menu = NSMenu()
    menu.autoenablesItems = false

    for stopId in group {
      let item = NSMenuItem(title: idToName[stopId]!, action: nil, keyEquivalent: "")
      item.tag = idToTag[stopId]!
      item.isEnabled = true
      menu.addItem(item)
    }

    return menu
  }

  private func trim(stopId: StopId) -> StopId {
    return String(stopId[..<stopId.index(stopId.startIndex, offsetBy: 3)])
  }
}
