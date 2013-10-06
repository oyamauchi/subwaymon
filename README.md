# SubwayMon

SubwayMon is a Mac OS X screensaver patterned after the in-station countdown
clocks in some New York City Subway stations.

## Building

The real-time train times feed uses Google's Protocol Buffers. You'll need to
get the protobuf C++ headers and libraries to build SubwayMon yourself. The
Xcode project is configured to look in `/opt/local/{include,lib}`, which is the
default MacPorts install location. If you're using MacPorts, just do:

    $ sudo port install protobuf-cpp

If you'd like to get protobuf some other way, you'll need to point the Xcode
project at the header tree and libprotobuf-lite.a.


## Data

The display is refreshed every 5 seconds (updating the time deltas given the
most recent data fetched) and the train time data is re-downloaded every
minute. The static GTFS file "stops.txt" is bundled with the screensaver; I'll
have to manually update it if it ever changes.

The feed is fetched from an endpoint on my server, which caches the feed fetched
from the MTA for up to 30 seconds. This is to comply with the MTA's terms of use.


## Code

The code that parses and looks through the feed data is in C++. View code is in
pure Objective-C as much as possible, and there's only one Objective-C++ file.

One oddity here is that the project is configured to compile with a C++ compiler
that mostly supports C++11 (Apple LLVM 4.2, based on LLVM 3.2), and to turn on
the compiler's C++11 support, but to use an old standard library that doesn't
have C++11 support (the libstdc++ that ships with OS X, whatever that is). This
is because the only C++ standard library available on OS X by default that
supports C++11 is libc++, but it's not binary-compatible with the protocol
buffers library (which was built against libstdc++).

This results in the weird situation that I'm using some C++11 features, but only
ones that don't require any C++11-only headers. So I'm using the auto type,
range for loops, uniform initialization, double right-angle-bracket syntax, and
lambdas. I don't get to use things like initializer lists, std::begin,
std::unordered_map, or move semantics (requires std::move).
