#!/usr/bin/env python3

import gtfs_realtime_pb2
import sys

data = open(sys.argv[1], 'rb').read()

message = gtfs_realtime_pb2.FeedMessage()
message.ParseFromString(data)

print(message)
