//
//  backend.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/4/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import Foundation

typealias TimeAndTrack = (Date, String)
typealias StopId = String

private func tripDestination(tripUpdate: TransitRealtime_TripUpdate) -> StopId {
  if let stu = tripUpdate.stopTimeUpdate.last {
    return stu.stopID
  } else {
    return "nowhere"
  }
}

private func arrival(atStop stopId: StopId,
                     tripUpdate: TransitRealtime_TripUpdate) -> TimeAndTrack? {
  assert(stopId.count == 3 || stopId.count == 4)
  if stopId.count == 4 {
    assert(stopId.last == "N" || stopId.last == "S")
  }

  for stu in tripUpdate.stopTimeUpdate {
    // Only consider a stop-time-update if it has a departure time listed. If it
    // doesn't, it's a train arriving at its terminus at the end of a trip, and
    // we don't want to show that as a train "arriving" at the station.
    // However, for purposes of time display, use the arrival time if available.
    if stu.hasDeparture, stu.stopID == stopId {
      let time = stu.hasArrival ? stu.arrival.time : stu.departure.time
      let extUpdate = stu.nyctStopTimeUpdate
      let track = extUpdate.hasActualTrack ? extUpdate.actualTrack : extUpdate.scheduledTrack

      return (Date(timeIntervalSince1970: Double(time)), track)
    }
  }

  return nil
}

struct Arrival {
  let train: String
  let destinationStopId: StopId
  let track: String
  let seconds: Int64
}

func arrivals(atStop stopId: StopId,
              feedMessages: [TransitRealtime_FeedMessage]) -> Array<Arrival> {
  let now = Date()

  var result = Array<Arrival>()

  for feedMessage in feedMessages {
    for entity in feedMessage.entity {
      if entity.hasTripUpdate, let timeAndTrack = arrival(atStop: stopId,
                                                          tripUpdate: entity.tripUpdate) {
        let arrivalTime = timeAndTrack.0
        let seconds = arrivalTime.timeIntervalSince(now)
        if seconds < 0 {
          continue
        }

        let destination = tripDestination(tripUpdate: entity.tripUpdate)
        if destination != stopId {
          result.append(Arrival(
            train: entity.tripUpdate.trip.routeID,
            destinationStopId: destination,
            track: timeAndTrack.1,
            seconds: Int64(seconds)
          ))
        }
      }
    }
  }

  result.sort(by: { a, b in a.seconds < b.seconds })

  return result
}
