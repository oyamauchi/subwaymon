// MenuManager.swift
// Copyright 2021 Owen Yamauchi

import Cocoa

class MenuManager {
  private let providerDefaultsKey = "SelectedProvider"
  private let routeDefaultsKey = "SelectedRoute"
  private let stopDefaultsKey = "SelectedStop"

  private var defaults: UserDefaults
  private var feedInfo: FeedInfo!
  private var onStopIdsSelected: ([StopId], FeedInfo) -> Void

  private var providerMenu: NSPopUpButton
  private var routeMenu: NSPopUpButton
  private var stopMenu: NSPopUpButton

  init(defaults: UserDefaults,
       providerMenu: NSPopUpButton,
       routeMenu: NSPopUpButton,
       stopMenu: NSPopUpButton,
       onStopIdsSelected: @escaping ([StopId], FeedInfo) -> Void)
  {
    self.defaults = defaults
    self.providerMenu = providerMenu
    self.routeMenu = routeMenu
    self.stopMenu = stopMenu
    self.onStopIdsSelected = onStopIdsSelected

    providerMenu.target = self
    providerMenu.action = #selector(providerMenuSelected)
    routeMenu.target = self
    routeMenu.action = #selector(routeMenuSelected)
    stopMenu.target = self
    stopMenu.action = #selector(stopMenuSelected)

    providerMenu.menu = FeedInfo.providerMenu
    selectItem(inMenu: providerMenu, withDefaultsKey: providerDefaultsKey)
    providerMenuSelected(providerMenu)
  }

  private func selectItem(inMenu menu: NSPopUpButton, withDefaultsKey key: String) {
    if let savedTitle = defaults.string(forKey: key) {
      menu.selectItem(withTitle: savedTitle)
    }
    if menu.selectedTag() < 0 {
      defaults.removeObject(forKey: key)
      menu.selectItem(at: 0)
    }
  }

  @objc
  func providerMenuSelected(_ sender: NSPopUpButton) {
    defaults.set(sender.titleOfSelectedItem, forKey: providerDefaultsKey)

    feedInfo = FeedInfo.feedInfo(forTag: sender.selectedTag())
    routeMenu.menu = feedInfo.routeMenu
    routeMenu.isEnabled = true
    selectItem(inMenu: routeMenu, withDefaultsKey: routeDefaultsKey)
    routeMenuSelected(routeMenu)
  }

  @objc
  func routeMenuSelected(_ sender: NSPopUpButton) {
    defaults.set(sender.titleOfSelectedItem, forKey: routeDefaultsKey)

    stopMenu.menu = feedInfo.stopMenu(forRouteTag: sender.selectedTag())
    stopMenu.isEnabled = true
    selectItem(inMenu: stopMenu, withDefaultsKey: stopDefaultsKey)
    stopMenuSelected(stopMenu)
  }

  @objc
  func stopMenuSelected(_ sender: NSPopUpButton) {
    defaults.set(sender.titleOfSelectedItem, forKey: stopDefaultsKey)

    let stopIds = feedInfo.stopIdsFor(stopTag: sender.selectedTag())
    onStopIdsSelected(stopIds, feedInfo)
  }
}
