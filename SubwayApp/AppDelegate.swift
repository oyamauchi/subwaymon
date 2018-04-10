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

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var subway: SubwayMonView!
  @IBOutlet weak var menu: NSPopUpButton!

  let defaultsKey = "SelectedStation"

  @IBAction func menuSelected(sender: NSPopUpButton) {
    let stopId = FeedInfo.shared.stopId(forTag: menu.selectedTag())
    subway.selectedStopId = stopId
    subway.needsDisplay = true

    UserDefaults.standard.set(stopId, forKey: defaultsKey)
  }

  func timerFired() {
    subway.needsDisplay = true
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
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

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
