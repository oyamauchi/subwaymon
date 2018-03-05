//
//  SubwayMonScreenSaverView.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/4/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import ScreenSaver

class SubwayMonScreenSaverView : ScreenSaverView {
  @IBOutlet var configSheet: NSWindow!
  @IBOutlet var popupMenu: NSPopUpButton!

  private var subwayView: SubwayMonView!

  private let kSelectedStationKey = "SelectedStation"

  @IBAction func closeSheet(sender: Any) {
    let defaults = ScreenSaverDefaults.init(forModuleWithName: "com.oyamauchi.SubwayMon")!
    defaults.set(self.popupMenu.selectedTag(), forKey: kSelectedStationKey)
    defaults.synchronize()

    self.subwayView.selectedStationTag = popupMenu.selectedTag()

    NSApplication.shared().endSheet(configSheet)
  }

  func selectedStationTag() -> Int {
    let defaults = ScreenSaverDefaults.init(forModuleWithName: "com.oyamauchi.SubwayMon")!
    let value = defaults.integer(forKey: kSelectedStationKey)
    // Grand Central on the Lex by default
    return value != 0 ? value : 631
  }

  override init?(frame: NSRect, isPreview: Bool) {
    super.init(frame: frame, isPreview: isPreview)

    self.animationTimeInterval = 5.0

    self.subwayView = SubwayMonView()
    self.subwayView.initialize(stationTag: self.selectedStationTag())
    self.addSubview(self.subwayView)

    Bundle.main.loadNibNamed("ConfigureSheet", owner: self, topLevelObjects: nil)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func animateOneFrame() {
    self.needsDisplay = true
  }

  override func hasConfigureSheet() -> Bool {
    return true
  }

  override func configureSheet() -> NSWindow? {
    return self.configSheet
  }
}

