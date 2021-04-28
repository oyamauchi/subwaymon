// AppDelegate.swift
// Copyright 2021 Owen Yamauchi

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  private let providerDefaultsKey = "SelectedProvider"
  private let routeDefaultsKey = "SelectedRoute"
  private let stopDefaultsKey = "SelectedStop"

  @IBOutlet var window: NSWindow!
  @IBOutlet var subway: SubwayMonView!
  @IBOutlet var providerMenu: NSPopUpButton!
  @IBOutlet var routeMenu: NSPopUpButton!
  @IBOutlet var stopMenu: NSPopUpButton!

  private var feedInfo: FeedInfo!
  private let defaults = UserDefaults.standard

  private func selectItem(inMenu menu: NSPopUpButton, withDefaultsKey key: String) {
    if let savedTitle = defaults.string(forKey: key) {
      menu.selectItem(withTitle: savedTitle)
    }
    if menu.selectedTag() < 0 {
      defaults.removeObject(forKey: key)
      menu.selectItem(at: 0)
    }
  }

  @IBAction func providerMenuSelected(_ sender: NSPopUpButton) {
    defaults.set(sender.titleOfSelectedItem, forKey: providerDefaultsKey)

    feedInfo = FeedInfo.feedInfo(forTag: sender.selectedTag())
    routeMenu.menu = feedInfo.routeMenu
    routeMenu.isEnabled = true
    selectItem(inMenu: routeMenu, withDefaultsKey: routeDefaultsKey)
    routeMenuSelected(routeMenu)
  }

  @IBAction func routeMenuSelected(_ sender: NSPopUpButton) {
    defaults.set(sender.titleOfSelectedItem, forKey: routeDefaultsKey)

    stopMenu.menu = feedInfo.stopMenu(forRouteTag: sender.selectedTag())
    stopMenu.isEnabled = true
    selectItem(inMenu: stopMenu, withDefaultsKey: stopDefaultsKey)
    stopMenuSelected(stopMenu)
  }

  @IBAction func stopMenuSelected(_ sender: NSPopUpButton) {
    defaults.set(sender.titleOfSelectedItem, forKey: stopDefaultsKey)

    let stopIds = feedInfo.stopIdsFor(stopTag: sender.selectedTag())
    subway.setStopIds(stopIds: stopIds, feedInfo: feedInfo)
    subway.needsDisplay = true
  }

  @objc
  func timerFired() {
    subway.needsDisplay = true
  }

  func applicationDidFinishLaunching(_: Notification) {
    providerMenu.menu = FeedInfo.providerMenu
    selectItem(inMenu: providerMenu, withDefaultsKey: providerDefaultsKey)
    providerMenuSelected(providerMenu)

    Timer.scheduledTimer(
      timeInterval: 5.0,
      target: self,
      selector: #selector(AppDelegate.timerFired),
      userInfo: nil,
      repeats: true
    )
  }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
    return true
  }
}
