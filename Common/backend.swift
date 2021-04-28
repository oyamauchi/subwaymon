//
//  backend.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/4/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

import Foundation

typealias StopId = String
typealias RouteId = String

struct StopUpdate: Codable {
  let headsign: String
  let route: RouteId
  let time: Int
}

struct Feed: Codable {
  let northbound: [StopUpdate]
  let southbound: [StopUpdate]
}
