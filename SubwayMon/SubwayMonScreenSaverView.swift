//
//  SubwayMonScreenSaverView.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/4/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import ScreenSaver

class SubwayMonScreenSaverView: ScreenSaverView {
  @IBOutlet var configSheet: NSWindow!
  @IBOutlet var popupMenu: NSPopUpButton!

  private var subwayView: SubwayMonView!

  private let kSelectedStationKey = "SelectedStation"

  @IBAction func closeSheet(sender _: Any) {
    let defaults = ScreenSaverDefaults(forModuleWithName: "com.oyamauchi.SubwayMon")!
    let stopId = FeedInfo.shared.stopId(forTag: popupMenu.selectedTag())
    defaults.set(stopId, forKey: kSelectedStationKey)
    defaults.synchronize()

    subwayView.selectedStopId = stopId

    NSApplication.shared().endSheet(configSheet)
  }

  override init?(frame: NSRect, isPreview: Bool) {
    super.init(frame: frame, isPreview: isPreview)

    Bundle(for: SubwayMonScreenSaverView.self).loadNibNamed(
      "ConfigureSheet",
      owner: self,
      topLevelObjects: nil
    )

    animationTimeInterval = 5.0

    let defaults = ScreenSaverDefaults(forModuleWithName: "com.oyamauchi.SubwayMon")!
    // Grand Central on the Lex by default
    let stopId = defaults.string(forKey: kSelectedStationKey) ?? "631"

    subwayView = SubwayMonView(frame: bounds)
    subwayView.initialize(stopId: stopId)
    addSubview(subwayView)

    popupMenu.menu = FeedInfo.shared.menu
    popupMenu.selectItem(withTag: FeedInfo.shared.tag(forStopId: stopId))
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func animateOneFrame() {
    needsDisplay = true
  }

  override func hasConfigureSheet() -> Bool {
    return true
  }

  override func configureSheet() -> NSWindow? {
    return configSheet
  }
}
