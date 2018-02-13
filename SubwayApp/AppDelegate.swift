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


  func applicationDidFinishLaunching(_ aNotification: Notification) {
    subway.initialize(631)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }


}

