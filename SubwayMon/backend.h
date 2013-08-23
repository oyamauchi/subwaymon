#pragma once

#include <string>
#include <vector>

struct Arrival {
  std::string train;
  std::string destination;
  std::string track;
  int64_t seconds;
};

std::vector<Arrival> arrivalsAt(const std::string& atStop,
                                const std::string& gtfsFeed,
                                const std::string& gtfsStops);
