// SubwayMonScreenSaverView.swift
// Copyright 2021 Owen Yamauchi

import ScreenSaver

class SubwayMonScreenSaverView: ScreenSaverView {
  @IBOutlet var configSheet: NSWindow!
  @IBOutlet var providerMenu: NSPopUpButton!
  @IBOutlet var routeMenu: NSPopUpButton!
  @IBOutlet var stopMenu: NSPopUpButton!

  private var subwayView: SubwayMonView!
  private var menuManager: MenuManager!

  private let defaults = ScreenSaverDefaults(forModuleWithName: "com.oyamauchi.SubwayMon")!

  private static let kSelectedProviderIdKey = "SelectedProviderId"
  private static let kSelectedStopIdsKey = "SelectedStopIds"

  @IBAction func closeSheet(sender _: Any) {
    configSheet.sheetParent?.endSheet(configSheet)
  }

  override init?(frame: NSRect, isPreview: Bool) {
    super.init(frame: frame, isPreview: isPreview)

    Bundle(for: SubwayMonScreenSaverView.self).loadNibNamed(
      "ConfigureSheet",
      owner: self,
      topLevelObjects: nil
    )

    animationTimeInterval = 5.0

    subwayView = SubwayMonView(frame: bounds)
    addSubview(subwayView)

    if let savedStopIds = defaults.stringArray(forKey: SubwayMonScreenSaverView.kSelectedStopIdsKey),
       let savedProviderId = defaults.string(forKey: SubwayMonScreenSaverView.kSelectedProviderIdKey),
       let feedInfo = FeedInfo.feedInfo(forProviderId: savedProviderId)
    {
      subwayView.setStopIds(stopIds: savedStopIds, feedInfo: feedInfo)
      subwayView.needsDisplay = true
    }

    menuManager = MenuManager(
      defaults: defaults,
      providerMenu: providerMenu,
      routeMenu: routeMenu,
      stopMenu: stopMenu,
      onStopIdsSelected: { [unowned self] (stopIds: [StopId], feedInfo: FeedInfo) -> Void in
        self.setAndSave(stopIds: stopIds, feedInfo: feedInfo)
      }
    )
  }

  func setAndSave(stopIds: [StopId], feedInfo: FeedInfo) {
    defaults.set(stopIds, forKey: SubwayMonScreenSaverView.kSelectedStopIdsKey)
    defaults.set(feedInfo.providerId, forKey: SubwayMonScreenSaverView.kSelectedProviderIdKey)
    defaults.synchronize()

    subwayView.setStopIds(stopIds: stopIds, feedInfo: feedInfo)
    subwayView.needsDisplay = true
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func animateOneFrame() {
    needsDisplay = true
  }

  override var hasConfigureSheet: Bool { true }
  override var configureSheet: NSWindow? { configSheet }
}
