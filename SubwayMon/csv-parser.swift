//
//  csv-parser.swift
//  SubwayMon
//
//  Created by Owen Yamauchi on 3/4/18.
//  Copyright © 2018 Owen Yamauchi. All rights reserved.
//

func parseCsv(_ input: String) -> Array<Array<String>> {
  var result = Array<Array<String>>()

  input.enumerateLines { line, _ in
    var fields = Array<String>()
    var field = String()
    var inQuoted = false
    var index = line.startIndex

    while index < line.endIndex {
      if inQuoted {
        if line[index] == "\"" {
          inQuoted = false
        } else if line[index] == "\\" && line[line.index(after: index)] == "\"" {
          field.append("\"")
          index = line.index(after: index)
        } else {
          field.append(line[index])
        }
      } else {
        switch line[index] {
        case ",":
          fields.append(field)
          field = String()
        case "\"":
          inQuoted = true
        default:
          field.append(line[index])
        }
      }

      index = line.index(after: index)
    }

    result.append(fields)
  }

  return result
}
