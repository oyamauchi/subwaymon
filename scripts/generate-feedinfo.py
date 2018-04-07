#!/usr/bin/env python3

from typing import *
import json
import os
import sys

import seqmerge

ROUTE_GROUPS = {
    '1, 2, 3': ['1', '2', '3'],
    '4, 5, 6': ['4', '5', '6', '6X'],
    '7': ['7', '7X'],
    '42 St Shuttle': ['GS'],
    'A, C, E, Rockaways Shuttle': ['A', 'C', 'E', 'H'],
    'B, D, F, M': ['B', 'D', 'F', 'M'],
    'G': ['G'],
    'J, Z': ['J', 'Z'],
    'L': ['L'],
    'N, Q, R, W': ['N', 'Q', 'R', 'W'],
    'Franklin Av Shuttle': ['FS'],
    'Staten Island Railway': ['SI']
}

FEED_FOR_ROUTE = {
    '1': 1,
    '2': 1,
    '3': 1,
    '4': 1,
    '5': 1,
    '6': 1,
    '6X': 1,
    'GS': 1,
    '7': 51,
    '7X': 51,
    'A': 26,
    'C': 26,
    'E': 26,
    'H': 26,
    'FS': 26,
    'B': 21,
    'D': 21,
    'F': 21,
    'M': 21,
    'G': 31,
    'J': 36,
    'Z': 36,
    'N': 16,
    'Q': 16,
    'R': 16,
    'W': 16,
    'L': 2,
    'SI': 11
}

FEED_DIR = sys.argv[1]

def get_stop_names() -> Dict[str, str]:
    result = {}
    for line in open(os.path.join(FEED_DIR, 'stops.txt'), 'r'):
        stop_id, _, stop_name = line.split(',')[:3]
        if stop_id == 'stop_id':
            continue
        result[stop_id] = stop_name
    return result


def get_route_trips() -> Dict[str, Set[str]]:
    result: Dict[str, Set[str]] = {}
    for line in open(os.path.join(FEED_DIR, 'trips.txt'), 'r'):
        route_id, service_id, trip_id = line.split(',')[:3]
        if route_id == 'route_id':
            continue

        if route_id not in result:
            result[route_id] = set()
        result[route_id].add(trip_id)
    return result


def get_trip_stops() -> Dict[str, List[str]]:
    result: Dict[str, List[str]] = {}

    for line in open(os.path.join(FEED_DIR, 'stop_times.txt'), 'r'):
        fields = line.split(',')
        if fields[0] == 'trip_id':
            continue

        trip_id = fields[0]

        trip_id_fields = trip_id.split('.')

        # Only look at northbound trips. It has to be northbound because there's
        # one station that's north-only (Aqueduct Racetrack).
        if not trip_id_fields[-1].startswith('N'):
            continue

        # Cut off the direction letter at the end
        stop_id = fields[3][:-1]

        if trip_id not in result:
            result[trip_id] = []
        result[trip_id].append(stop_id)

    return result


stop_names = get_stop_names()
trips_for_route = get_route_trips()
stops_for_trip = get_trip_stops()

# {groups: {title : [stops]}, stopinfo: {stop: [feeds]}}

groups: Dict[str, List[str]] = {}
feeds_for_stop: Dict[str, Set[int]] = {}

def process_route(route_id: str) -> Set[Tuple[str, ...]]:
    trips = trips_for_route[route_id]
    feed = FEED_FOR_ROUTE[route_id]
    seqs = set()

    for trip_id in trips:
        if trip_id not in stops_for_trip:
            continue

        trip_stops = stops_for_trip[trip_id]

        seqs.add(tuple(trip_stops))

        for stop in trip_stops:
            if stop not in feeds_for_stop:
                feeds_for_stop[stop] = set()
            feeds_for_stop[stop].add(feed)

    return seqs


for title, route_ids in ROUTE_GROUPS.items():
    seqs: Set[Tuple[str, ...]] = set()

    for route_id in route_ids:
        seqs.update(process_route(route_id))

    merged = seqmerge.seqmerge(seqs)
    merged.reverse()

    groups[title] = merged


outputdict = {
    'groups': groups,
    'stopinfo': {
        k: {
            'name': stop_names[k],
            'feeds': list(v),
        } for k,v in feeds_for_stop.items()
    }
}

json.dump(outputdict, sys.stdout, indent=2)
