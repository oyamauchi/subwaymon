
#include "backend.h"

#include <ctime>
#include <cstdio>
#include <iostream>
#include <sstream>

#include "csv-parser.h"
#include "nyct-subway.pb.h"

typedef std::map<std::string, std::string> StopIdToNameMap;

StopIdToNameMap buildStopIdMap(const std::string& gtfsStops) {
  auto parsed = parseCSV(gtfsStops);
  StopIdToNameMap result;
  
  for (auto const& line : parsed) {
    if (line.empty() || line.front() == "stop_id") {
      // Header
      continue;
    }
    result[line[0]] = line[2];
  }
  
  return result;
}


typedef std::pair<int64_t, std::string> TimeAndTrack;

std::string tripDestination(const transit_realtime::TripUpdate& tripUpdate,
                            const StopIdToNameMap& stopMap) {
  if (tripUpdate.stop_time_update_size() == 0) {
    return "nowhere";
  }

  auto const& stu = tripUpdate.stop_time_update(tripUpdate.stop_time_update_size() - 1);
  auto const& stopId = stu.stop_id();

  return stopMap.find(stopId)->second;
}

TimeAndTrack arrivalAtStop(const transit_realtime::TripUpdate& tripUpdate,
                           const std::string& stopId) {
  assert(stopId.size() == 3 || stopId.size() == 4);
  if (stopId.size() == 4) {
    assert(stopId[3] == 'N' || stopId[3] == 'S');
  }

  for (int i = 0; i < tripUpdate.stop_time_update_size(); ++i) {
    auto const& stu = tripUpdate.stop_time_update(i);

    // Only consider a stop-time-update if it has a departure time listed. If it
    // doesn't, it's a train arriving at its terminus at the end of a trip, and
    // we don't want to show that as a train "arriving" at the station.
    // However, for purposes of time display, use the arrival time if available.
    if (stu.has_departure() && stu.stop_id().find(stopId) == 0) {
      auto time = (stu.has_arrival() ? stu.arrival().time() : stu.departure().time());
      auto const& extUpdate = stu.GetExtension(nyct_stop_time_update);
      auto const& track = (extUpdate.has_actual_track()
                           ? extUpdate.actual_track()
                           : extUpdate.scheduled_track());

      return { time, track };
    }
  }

  return { 0, "" };
}

std::vector<Arrival> arrivalsAt(const std::string& atStop,
                                const std::string& gtfsFeed,
                                const std::string& gtfsStops) {
  GOOGLE_PROTOBUF_VERIFY_VERSION;

  transit_realtime::FeedMessage fm;
  bool parsed = fm.ParseFromString(gtfsFeed);
  if (!parsed) {
    std::cerr << "couldn't parse your thign!\n";
    return std::vector<Arrival> {};
  }

  StopIdToNameMap stopMap = buildStopIdMap(gtfsStops);
  std::time_t now = std::time(nullptr);
  
  std::vector<Arrival> arrivals;

  for (int i = 0; i < fm.entity_size(); ++i) {
    auto const& entity = fm.entity(i);
    if (entity.has_trip_update()) {
      auto timeAndTrack = arrivalAtStop(entity.trip_update(), atStop);
      auto arrivalTime = timeAndTrack.first;
      if (arrivalTime < now) {
        continue;
      }

      auto seconds = arrivalTime - now;
      Arrival arr = {
        entity.trip_update().trip().route_id(),
        tripDestination(entity.trip_update(), stopMap),
        timeAndTrack.second,
        seconds
      };
      arrivals.push_back(arr);
    }
  }
  
  auto byTime = [](const Arrival& lhs, const Arrival& rhs) {
    return lhs.seconds < rhs.seconds;
  };

  std::sort(arrivals.begin(), arrivals.end(), byTime);
  return arrivals;
}

