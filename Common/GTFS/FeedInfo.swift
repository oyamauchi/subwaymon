//
//  StopsFileInfo.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/10/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import AppKit

class FeedInfo {
  private static let providerIds = ["mta"]
  private static var feedInfos = [Int: FeedInfo]()
  static let providerMenu = createProviderMenu()

  private struct StopInfo: Codable {
    let ids: [StopId]
    let name: String
  }

  private struct RouteInfo: Codable {
    let routeId: RouteId
    let name: String
    let symbolText: String
    let symbolTextColor: String
    let symbolShape: String
    let symbolColor: String
    let stops: [StopInfo]
  }

  private struct ProviderInfo: Codable {
    let name: String
    let routes: [RouteInfo]
  }

  private static func createProviderMenu() -> NSMenu {
    var index = 0
    let menu = NSMenu()
    menu.autoenablesItems = false

    for providerId in providerIds {
      let feedInfo = FeedInfo(providerId: providerId)

      let item = NSMenuItem(title: feedInfo.name, action: nil, keyEquivalent: "")
      item.isEnabled = true
      item.tag = index
      index += 1
      menu.addItem(item)

      feedInfos[item.tag] = feedInfo
    }

    return menu
  }

  private var routeTagToStopDicts = [Int: [StopInfo]]()
  private var stopTagToStopIds = [Int: [StopId]]()

  private var routeToSymbol = [RouteId: RouteSymbol]()

  private(set) var routeMenu: NSMenu!
  private(set) var providerId: String!
  private(set) var name: String!

  private init(providerId: String) {
    self.providerId = providerId

    let url = Bundle(for: SubwayMonView.self).url(forResource: providerId,
                                                  withExtension: "json")!
    let data = try? Data(contentsOf: url)
    let providerInfo = try? JSONDecoder().decode(ProviderInfo.self, from: data!)
    self.name = providerInfo!.name

    var routeTag = 1
    routeMenu = NSMenu()
    routeMenu.autoenablesItems = false

    for routeInfo in providerInfo!.routes {
      let symbol: RouteSymbol = RouteSymbol(
        text: routeInfo.symbolText,
        textColor: RouteSymbol.colorFrom(hexString: routeInfo.symbolTextColor),
        shape: RouteSymbol.Shape(rawValue: routeInfo.symbolShape)!,
        color: RouteSymbol.colorFrom(hexString: routeInfo.symbolColor))
      routeToSymbol[routeInfo.routeId] = symbol

      routeTagToStopDicts[routeTag] = routeInfo.stops

      let menuItem = NSMenuItem(title: routeInfo.name, action: nil, keyEquivalent: "")
      menuItem.isEnabled = true
      menuItem.tag = routeTag

      routeTag += 1
      routeMenu.addItem(menuItem)
    }
  }

  static func feedInfo(forTag tag: Int) -> FeedInfo {
    return feedInfos[tag]!
  }

  func stopMenu(forRouteTag routeTag: Int) -> NSMenu {
    stopTagToStopIds.removeAll()

    let stopInfos = routeTagToStopDicts[routeTag]!

    var stopTag = 1
    let menu = NSMenu()
    menu.autoenablesItems = false

    for stopInfo in stopInfos {
      let item = NSMenuItem(title: stopInfo.name, action: nil, keyEquivalent: "")
      item.tag = stopTag
      item.isEnabled = true

      stopTagToStopIds[stopTag] = stopInfo.ids

      menu.addItem(item)
      stopTag += 1
    }

    return menu
  }

  func stopIdsFor(stopTag: Int) -> [StopId] {
    return stopTagToStopIds[stopTag]!
  }

  func symbolFor(routeId: String) -> RouteSymbol {
    return routeToSymbol[routeId]!
  }
}
