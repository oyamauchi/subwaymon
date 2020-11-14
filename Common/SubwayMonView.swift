//
//  SwiftSubwayMonView.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/4/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import AppKit

class SubwayMonView: NSView {
  private var trainViews = [TrainView]()

  private var feedMessages = [Int: TransitRealtime_FeedMessage]()
  private var feedsInProgress = Set<Int>()

  private var feedInfo: FeedInfo!
  private var selectedStopId: StopId!

  //////////////////////////////////////////////////////////////////////////////////
  //

  // MARK: Public interface

  //
  //////////////////////////////////////////////////////////////////////////////////

  override init(frame: NSRect) {
    super.init(frame: frame)
    createSubviews()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    createSubviews()
  }

  private func createSubviews() {
    for _ in 0 ..< 8 {
      let train = TrainView()
      train.isHidden = true
      addSubview(train)
      trainViews.append(train)
    }
    setSubviewSizes()
  }

  func setStopId(stopId: StopId, feedInfo: FeedInfo) {
    selectedStopId = stopId
    self.feedInfo = feedInfo
    sendRequest()
  }

  //////////////////////////////////////////////////////////////////////////////////
  //

  // MARK: View logic

  //
  //////////////////////////////////////////////////////////////////////////////////

  private func setSubviewSizes() {
    let rowHeight = frame.size.height / 8
    let padding = 0.1 * rowHeight

    for i in 0 ..< 8 {
      let y = frame.size.height - (CGFloat(i + 1) * rowHeight) + padding
      let height = rowHeight - padding * 2
      trainViews[i].setFrameOrigin(NSMakePoint(padding, y))
      trainViews[i].setFrameSize(NSMakeSize(frame.size.width - padding * 2, height))
    }
  }

  private func updateViews(arrivals: Array<Arrival>, top: Bool) {
    let offset = top ? 0 : 4
    var i = 0

    while i < min(arrivals.count, 4) {
      let tv = trainViews[i + offset]
      let arrival = arrivals[i]
      i += 1

      tv.symbol = text(forRoute: arrival.train)
      tv.color = color(forRoute: arrival.train)
      tv.isDiamond = (arrival.train.last == "X")
      tv.isBlackText = (["N", "Q", "R", "W"].contains(arrival.train))
      tv.text = feedInfo.name(ofStopId: arrival.destinationStopId)
      tv.minutes = Int(arrival.seconds + 29) / 60 // round to nearest minute

      tv.isHidden = false
      tv.needsDisplay = true
    }

    while i < 4 {
      trainViews[i + offset].isHidden = true
      i += 1
    }
  }

  override func resize(withOldSuperviewSize oldSize: NSSize) {
    super.resize(withOldSuperviewSize: oldSize)
    setSubviewSizes()
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor.black.set()
    dirtyRect.fill()

    if let stopId = selectedStopId {
      // Read the arrivals twice: once for the northbound direction of our stop id and once for the
      // southbound. The GS shuttle considers TS to be north and GC to be south.
      let northArrs = arrivals(
        atStop: stopId + "N",
        feedMessages: Array(feedMessages.values)
      )
      updateViews(arrivals: northArrs, top: true)

      let southArrs = arrivals(
        atStop: stopId + "S",
        feedMessages: Array(feedMessages.values)
      )
      updateViews(arrivals: southArrs, top: false)

      // Draw the separator between the two halves
      let line = NSBezierPath()
      line.move(to: NSMakePoint(0, bounds.size.height / 2))
      line.line(to: NSMakePoint(bounds.size.width, bounds.size.height / 2))
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
    for feed in feedInfo.feeds(forStopId: selectedStopId) {
      if feedsInProgress.contains(feed) {
        continue
      }

      feedsInProgress.insert(feed)

      let url = URL(string: "http://subwaymon.nfshost.com/fetch.php?feed=\(feed)")!

      let sessionTask = URLSession.shared.dataTask(with: url) { data, _, _ in
        self.feedsInProgress.remove(feed)
        self.feedMessages[feed] = try? TransitRealtime_FeedMessage(serializedData: data!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0, execute: self.sendRequest)
      }

      sessionTask.resume()
    }
  }
}
