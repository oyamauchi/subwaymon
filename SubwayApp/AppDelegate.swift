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

  private let defaults = UserDefaults.standard
  private var menuManager: MenuManager!

  @objc
  func timerFired() {
    subway.needsDisplay = true
  }

  func applicationDidFinishLaunching(_: Notification) {
    menuManager = MenuManager(
      defaults: defaults,
      providerMenu: providerMenu,
      routeMenu: routeMenu,
      stopMenu: stopMenu,
      onStopIdsSelected: {
        [unowned self]
        (stopIds: [StopId], feedInfo: FeedInfo) -> Void in
        self.subway.setStopIds(stopIds: stopIds, feedInfo: feedInfo)
        self.subway.needsDisplay = true
      }
    )

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
