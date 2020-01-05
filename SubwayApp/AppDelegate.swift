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
  @IBOutlet var menu: NSPopUpButton!

  let defaultsKey = "SelectedStation"

  @IBAction func menuSelected(sender _: NSPopUpButton) {
    let stopId = FeedInfo.shared.stopId(forTag: menu.selectedTag())
    subway.selectedStopId = stopId
    subway.needsDisplay = true

    UserDefaults.standard.set(stopId, forKey: defaultsKey)
  }

  @objc
  func timerFired() {
    subway.needsDisplay = true
  }

  func applicationDidFinishLaunching(_: Notification) {
    let selectedStopId = UserDefaults.standard.string(forKey: defaultsKey) ?? "631"
    let tag = FeedInfo.shared.tag(forStopId: selectedStopId)

    subway.initialize(stopId: selectedStopId)
    menu.menu = FeedInfo.shared.menu
    menu.selectItem(withTag: tag)

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
