//
//  AppDelegate.swift
//  SubwayApp
//
//  Created by Owen Yamauchi on 2/12/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet var window: NSWindow!
  @IBOutlet var subway: SubwayMonView!
  @IBOutlet var providerMenu: NSPopUpButton!
  @IBOutlet var routeMenu: NSPopUpButton!
  @IBOutlet var stopMenu: NSPopUpButton!

  var feedInfo: FeedInfo!

  @IBAction func providerMenuSelected(_ sender: NSPopUpButton) {
    feedInfo = FeedInfo(providerTag: sender.selectedTag())
    routeMenu.menu = feedInfo.routeMenu
    routeMenu.isEnabled = true
    routeMenu.selectItem(at: 0)
    routeMenuSelected(routeMenu)
  }

  @IBAction func routeMenuSelected(_ sender: NSPopUpButton) {
    stopMenu.menu = feedInfo.stopMenu(forRouteTag: sender.selectedTag())
    stopMenu.isEnabled = true
    stopMenu.selectItem(at: 0)
    stopMenuSelected(stopMenu)
  }

  @IBAction func stopMenuSelected(_ sender: NSPopUpButton) {
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
    providerMenu.selectItem(at: 0)
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
