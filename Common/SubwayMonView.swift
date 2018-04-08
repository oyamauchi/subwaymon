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

  private var feedMessages = Dictionary<Int, TransitRealtime_FeedMessage>()
  private var feedsInProgress = Set<Int>()

  var selectedStopId: StopId! {
    didSet {
      self.sendRequest()
    }
  }

  //////////////////////////////////////////////////////////////////////////////////
  //
  // MARK: Public interface
  //
  //////////////////////////////////////////////////////////////////////////////////

  func initialize(stopId: StopId) {
    for _ in 0 ..< 8 {
      let train = TrainView()
      train.isHidden = true
      self.addSubview(train)
      trainViews.append(train)
    }

    selectedStopId = stopId

    self.setSubviewSizes()
    self.sendRequest()
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

      tv.symbol = char(forRoute: arrival.train)
      tv.color = color(forRoute: arrival.train)
      tv.isDiamond = (arrival.train.last == "X")
      tv.isBlackText = (["N", "Q", "R", "W"].contains(arrival.train))
      tv.text = StopsFileInfo.shared.name(ofStopId: arrival.destinationStopId)
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

    if let stopId = selectedStopId {
      // Read the arrivals twice: once for the northbound direction of our stop id and once for the
      // southbound. The GS shuttle considers TS to be north and GC to be south.
      let northArrs = arrivals(
        atStop: stopId + "N",
        feedMessages: Array(self.feedMessages.values)
      )
      self.updateViews(arrivals: northArrs, top: true)

      let southArrs = arrivals(
        atStop: stopId + "S",
        feedMessages: Array(self.feedMessages.values)
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
    for feed in StopsFileInfo.shared.feeds(forStopId: selectedStopId) {
      if feedsInProgress.contains(feed) {
        continue
      }

      feedsInProgress.insert(feed)

      let url = URL.init(string: "http://subwaymon.nfshost.com/fetch.php?feed=\(feed)")!

      let sessionTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
        self.feedsInProgress.remove(feed)
        self.feedMessages[feed] = try? TransitRealtime_FeedMessage(serializedData: data!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0, execute: self.sendRequest)
      }

      sessionTask.resume()
    }
  }
}
