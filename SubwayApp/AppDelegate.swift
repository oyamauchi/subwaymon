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
    subway.selectedStationTag = menu.selectedTag()
    subway.needsDisplay = true

    UserDefaults.standard.set(menu.selectedTag(), forKey: defaultsKey)
  }

  func timerFired() {
    subway.needsDisplay = true
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let selectedTag = UserDefaults.standard.integer(forKey: defaultsKey)

    subway.initialize(selectedTag == 0 ? 631 : selectedTag)
    subway.populateMenu(menu)

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
