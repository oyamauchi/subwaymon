
#include "csv-parser.h"

#include <sstream>

std::vector<std::vector<std::string>> parseCSV(const std::string& input) {
  std::vector<std::vector<std::string>> result;

  std::istringstream stream { input };

  while (stream.good()) {
    constexpr int maxLineSize = 2048;
    char buffer[maxLineSize];
    stream.getline(buffer, maxLineSize);

    std::vector<std::string> fields {};
    std::ostringstream field {};
    auto* ptr = buffer;
    bool inQuoted = false;

    while (*ptr) {
      if (inQuoted) {
        if (*ptr == '"') {
          inQuoted = false;
        } else if (*ptr == '\\' && *(ptr + 1) == '"') {
          field << '"';
          ++ptr;
        } else {
          field << *ptr;
        }
      } else {
        if (*ptr == ',') {
          fields.push_back(field.str());
          field.str("");
        } else if (*ptr == '"') {
          inQuoted = true;
        } else {
          field << *ptr;
        }
      }

      ++ptr;
    }

    result.push_back(fields);
  }

  return result;
}
