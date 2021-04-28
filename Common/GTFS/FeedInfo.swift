//
//  StopsFileInfo.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/10/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import AppKit

class FeedInfo {
  static let providers = ["mta"]
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

    for provider in providers {
      let item = NSMenuItem(title: provider, action: nil, keyEquivalent: "")
      item.isEnabled = true
      item.tag = index
      index += 1
      menu.addItem(item)
    }

    return menu
  }

  private var routeTagToStopDicts = [Int: [StopInfo]]()
  private var stopTagToStopIds = [Int: [StopId]]()

  private var routeToSymbol = [RouteId: RouteSymbol]()

  private(set) var routeMenu: NSMenu!
  private(set) var provider: String!

  init(providerTag: Int) {
    provider = FeedInfo.providers[providerTag]
    let url = Bundle(for: SubwayMonView.self).url(forResource: provider,
                                                    withExtension: "json")!
    let data = try? Data(contentsOf: url)
    let providerInfo = try? JSONDecoder().decode(ProviderInfo.self, from: data!)

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
