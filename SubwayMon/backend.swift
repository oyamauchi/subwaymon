//
//  backend.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/4/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import Foundation

typealias StopIdToNameMap = Dictionary<String, String>
typealias TimeAndTrack = (Date, String)

private func buildStopIdMap(gtfsStops: String) -> StopIdToNameMap {
  let parsed = CSV.parseCsv(gtfsStops)
  var result = StopIdToNameMap()

  for line in parsed {
    if line.isEmpty || line.first == "stop_id" {
      continue
    }
    result[line[0]] = line[2]
  }

  return result
}

private func tripDestination(tripUpdate: TransitRealtime_TripUpdate,
                             stopMap: StopIdToNameMap
  ) -> String {
  if let stu = tripUpdate.stopTimeUpdate.last {
    let stopId = stu.stopID
    return stopMap[stopId]!
  } else {
    return "nowhere"
  }
}

private func arrival(atStop stopId: String,
                     tripUpdate: TransitRealtime_TripUpdate
  ) -> TimeAndTrack? {
  assert(stopId.count == 3 || stopId.count == 4)
  if stopId.count == 4 {
    assert(stopId.last == "N" || stopId.last == "S")
  }

  for stu in tripUpdate.stopTimeUpdate {
    // Only consider a stop-time-update if it has a departure time listed. If it
    // doesn't, it's a train arriving at its terminus at the end of a trip, and
    // we don't want to show that as a train "arriving" at the station.
    // However, for purposes of time display, use the arrival time if available.
    if stu.hasDeparture && stu.stopID == stopId {
      let time = stu.hasArrival ? stu.arrival.time : stu.departure.time
      let extUpdate = stu.nyctStopTimeUpdate
      let track = extUpdate.hasActualTrack ? extUpdate.actualTrack : extUpdate.scheduledTrack

      return (Date(timeIntervalSince1970: Double(time)), track)
    }
  }

  return nil
}

// TODO: These shouldn't extend NSObject, Backend shouldn't be a class

class SwiftArrival : NSObject {
  let train: String
  let destination: String
  let track: String
  let seconds: Int64
  init(train: String, destination: String, track: String, seconds: Int64) {
    self.train = train
    self.destination = destination
    self.track = track
    self.seconds = seconds
  }
}

class Backend : NSObject {
  class func arrivals(atStop stopId: String, gtfsFeed: Data, gtfsStops: String) -> Array<SwiftArrival> {
    var fm: TransitRealtime_FeedMessage

    do {
      fm = try TransitRealtime_FeedMessage(serializedData: gtfsFeed)
    } catch {
      print("couldn't parse your thign!")
      return []
    }

    let stopMap = buildStopIdMap(gtfsStops: gtfsStops)
    let now = Date()

    var result = Array<SwiftArrival>()

    for entity in fm.entity {
      if entity.hasTripUpdate, let timeAndTrack = arrival(atStop: stopId,
                                                          tripUpdate: entity.tripUpdate) {
        let arrivalTime = timeAndTrack.0
        let seconds = arrivalTime.timeIntervalSince(now)
        if seconds < 0 {
          continue
        }

        result.append(SwiftArrival(
          train: entity.tripUpdate.trip.routeID,
          destination: tripDestination(tripUpdate: entity.tripUpdate, stopMap: stopMap),
          track: timeAndTrack.1,
          seconds: Int64(seconds)
        ))
      }
    }

    result.sort(by: { a, b in a.seconds < b.seconds})

    return result
  }
}
