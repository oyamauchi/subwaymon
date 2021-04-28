// backend.swift
// Copyright 2021 Owen Yamauchi

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
