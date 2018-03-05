//
//  SwiftSubwayMonView.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/4/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import AppKit

class SubwayMonView : NSView {
  private var trainViews = Array<TrainView>()

  private var gtfsStops: Array<Array<String>>!
  private var stopMap: StopIdToNameMap!

  private var feedMessage: TransitRealtime_FeedMessage?
  private var sessionTask: URLSessionTask?

  var selectedStationTag: Int = 631

  //////////////////////////////////////////////////////////////////////////////////
  //
  // MARK: Public interface
  //
  //////////////////////////////////////////////////////////////////////////////////

  func initialize(stationTag: Int) {
    for _ in 0 ..< 8 {
      let train = TrainView()
      train.isHidden = true
      self.addSubview(train)
      trainViews.append(train)
    }

    self.setSubviewSizes()

    let stopsPath = Bundle(for: SubwayMonView.self).path(forResource: "stops", ofType: "txt")!
    let rawGtfsStops = try? String.init(contentsOfFile: stopsPath)

    self.gtfsStops = parseCsv(rawGtfsStops!)
    self.stopMap = buildStopIdMap(parsedGtfsStops: self.gtfsStops)

    self.selectedStationTag = stationTag

    self.sendRequest()
  }

  func populate(menu: NSPopUpButton) {
    // This is pretty heinous engineering. It assumes the stops file is sorted and is going to be a
    // pain to change if we ever get real-time data for more lines. Whatever.

    var section = 0
    menu.removeAllItems()
    menu.addItem(withTitle: "Broadway - 7 Av trains")
    menu.lastItem!.isEnabled = false

    for line in self.gtfsStops {
      let stopId = line[0]
      let first = stopId.first!

      // We don't want the directional stop ids (like 631N), or the ones for the B Division, or
      // the ones for the Flushing line (i.e. 7 train).
      if stopId.count != 3 || first < "1" || first > "9" || first == "7" {
        continue
      }

      // If we're seeing 4xx stops (i.e. 4 train stops) for the first time, or a 9xx stop (the GS
      // shuttle), start a new section.
      if first == "4" && section == 0 {
        menu.menu!.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Lexington Av trains")
        menu.lastItem!.isEnabled = false
        section = 1
      } else if first == "9" && section == 1 {
        menu.menu!.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "42 St Shuttle")
        menu.lastItem!.isEnabled = false
        section = 2
      }

      menu.addItem(withTitle: line[2])
      menu.lastItem!.tag = Int(stopId)!
      menu.lastItem!.isEnabled = true
      menu.lastItem!.indentationLevel = 1
    }

    menu.selectItem(withTag: self.selectedStationTag)
  }

  //////////////////////////////////////////////////////////////////////////////////
  //
  // MARK: View logic
  //
  //////////////////////////////////////////////////////////////////////////////////

  private func setSubviewSizes() {
    let rowHeight = self.frame.size.height / 8
    let padding = 0.1 * rowHeight

    for i in 0..<8 {
      let y = self.frame.size.height - (CGFloat(i + 1) * rowHeight) + padding
      let height = rowHeight - padding * 2
      trainViews[i].setFrameOrigin(NSMakePoint(padding, y))
      trainViews[i].setFrameSize(NSMakeSize(self.frame.size.width - padding * 2, height))
    }
  }

  private func updateViews(arrivals: Array<Arrival>, top: Bool) {
    let offset = top ? 0 : 4
    var i = 0

    while i < min(arrivals.count, 4) {
      let tv = self.trainViews[i + offset]
      let arrival = arrivals[i]
      i += 1

      var symbol: Character
      switch (arrival.train) {
      case "6X":
        symbol = "6"
      case "GS":
        symbol = "S"
      default:
        symbol = arrival.train.first!
      }

      let shape = arrival.train == "6X" ? LineShape.Diamond : LineShape.Circle
      let color = LineColor.forSymbol(symbol)

      tv.symbol = symbol
      tv.shape = shape
      tv.color = color
      tv.text = arrival.destination
      tv.minutes = Int(arrival.seconds + 29) / 60  // round to nearest minute

      tv.isHidden = false
      tv.needsDisplay = true
    }

    while i < 4 {
      self.trainViews[i + offset].isHidden = true
      i += 1
    }
  }

  override func resize(withOldSuperviewSize oldSize: NSSize) {
    super.resize(withOldSuperviewSize: oldSize)
    self.setSubviewSizes()
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor.black.set()
    NSRectFill(dirtyRect)

    if let feedMessage = self.feedMessage {
      // Read the arrivals twice: once for the northbound direction of our stop id and once for the
      // southbound. The GS shuttle considers TS to be north and GC to be south.
      let northArrs = arrivals(
        atStop: "\(self.selectedStationTag)N",
        feedMessage: feedMessage,
        stopMap: self.stopMap
      )
      self.updateViews(arrivals: northArrs, top: true)

      let southArrs = arrivals(
        atStop: "\(self.selectedStationTag)S",
        feedMessage: feedMessage,
        stopMap: self.stopMap
      )
      self.updateViews(arrivals: southArrs, top: false)

      // Draw the separator between the two halves
      let line = NSBezierPath()
      line.move(to: NSMakePoint(0, self.bounds.size.height / 2))
      line.line(to: NSMakePoint(self.bounds.size.width, self.bounds.size.height / 2))
      line.lineWidth = 2.5
      NSColor.white.set()
      line.stroke()
    }
  }

  //////////////////////////////////////////////////////////////////////////////////
  //
  // MARK: Data fetching
  //
  //////////////////////////////////////////////////////////////////////////////////

  private func sendRequest() {
    if sessionTask != nil {
      return
    }

    let url = URL.init(string: "http://subwaymon.nfshost.com/fetch.php")!

    self.sessionTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
      if self.feedMessage == nil {
        DispatchQueue.main.async(execute: { self.needsDisplay = true })
      }

      self.feedMessage = try? TransitRealtime_FeedMessage(serializedData: data!)
      self.sessionTask = nil

      DispatchQueue.main.asyncAfter(deadline: .now() + 60.0, execute: self.sendRequest)
    }

    self.sessionTask!.resume()
  }
}
