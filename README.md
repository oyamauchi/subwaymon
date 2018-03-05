# SubwayMon

SubwayMon is a Mac OS X screensaver patterned after the in-station countdown
clocks in some New York City Subway stations.

![Screenshot](http://i.imgur.com/BMA0tWa.png "Arrivals at Grand Central")

## Building

There are two targets: `SubwayMon` (the screensaver itself) and `SubwayApp` (a
standalone Mac OS app). The app is there so you can test the thing without
installing and previewing a screensaver in System Preferences.

`SubwayMonScreenSaverView` and `AppDelegate` are the main files of the
screensaver and app, respectively; they are pretty minimal, and as much logic
as possible should be shared between the two targets.

## Data

The display is refreshed every 5 seconds (updating the time deltas given the
most recent data fetched) and the train time data is re-downloaded every
minute. The static GTFS file "stops.txt" is bundled with the screensaver; I'll
have to manually update it if it ever changes.

The feed is fetched from an endpoint on my server, which caches the feed fetched
from the MTA for up to 30 seconds. This is to comply with the MTA's terms of use.
