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


  @IBAction func menuSelected(sender: NSPopUpButton) {
    subway.selectedStationTag = menu.selectedTag()
    subway.needsDisplay = true
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    subway.initialize(631)
    subway.populateMenu(menu)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
