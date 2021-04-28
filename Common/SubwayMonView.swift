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

  private var feed: Feed?
  private var feedInProgress = false

  private var feedInfo: FeedInfo!
  private var selectedStopIds: [StopId]!

  //////////////////////////////////////////////////////////////////////////////////
  //

  // MARK: Public interface

  //
  //////////////////////////////////////////////////////////////////////////////////

  override func viewDidMoveToWindow() {
    for _ in 0 ..< 8 {
      let train = TrainView()
      train.isHidden = true
      addSubview(train)
      trainViews.append(train)
    }
  }

  func setStopIds(stopIds: [StopId], feedInfo: FeedInfo) {
    selectedStopIds = stopIds
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

  private func updateViews(updates: [StopUpdate], top: Bool) {
    let now = Date()
    let offset = top ? 0 : 4
    var i = 0

    while i < min(updates.count, 4) {
      let tv = trainViews[i + offset]
      let update = updates[i]
      i += 1

      let arrivalTime = Date(timeIntervalSince1970: Double(update.time))
      let seconds = arrivalTime.timeIntervalSince(now)

      tv.symbol = feedInfo.symbolFor(routeId: update.route)
      tv.text = update.headsign
      tv.minutes = Int(seconds + 29) / 60 // round to nearest minute

      tv.isHidden = false
      tv.needsDisplay = true
    }

    while i < 4 {
      trainViews[i + offset].isHidden = true
      i += 1
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    setSubviewSizes()

    NSColor.black.set()
    dirtyRect.fill()

    updateViews(updates: feed?.northbound ?? [], top: true)
    updateViews(updates: feed?.southbound ?? [], top: false)

    if self.feed != nil {
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
    if feedInProgress {
      return
    }

    feedInProgress = true
    feed = nil

    #if LOCAL_SERVER
    let host = "http://localhost:5000"
    #else
    let host = "https://subwaymon.owenyamauchi.com"
    #endif

    let queryString = selectedStopIds.map() {
      "stop_id=\($0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
    }.joined(separator: "&")

    let url = URL(string: "\(host)/feed/\(feedInfo.providerId!)?\(queryString)")!

    let sessionTask = URLSession.shared.dataTask(with: url) { data, _, _ in
      self.feedInProgress = false
      if let data = data {
        self.feed = try? JSONDecoder().decode(Feed.self, from: data)
      }
      DispatchQueue.main.async { self.needsDisplay = true }
      DispatchQueue.main.asyncAfter(deadline: .now() + 60.0, execute: self.sendRequest)
    }

    sessionTask.resume()
  }
}
