//
// Copyright (c) 2018 ANONYMISED
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import Foundation

/// Represents an 'event' in broad sense: someone is doing something for some time
/// (e.g. user visits a message or types on the keyboard for some time)
struct Event: Codable {
    
    /// Unixtime (ms) of start of visit
    let startUnixtime: Int
    
    /// Unixtime (ms) of end of visit, -1 if invalid
    private(set) var endUnixtime: Int = -1
    
    /// Creates a new event now (can be done() later but will be marked as invalid)
    init() {
        startUnixtime = Date().unixTime
    }
    
    /// Trivial init, traps if end is not at least equal to start
    init(_ start: Int, _ end: Int) {
        if !(end >= start) {
            fatalError("Attempted to create an event with negative duration")
        }
        self.startUnixtime = start
        self.endUnixtime = end
    }
    
    /// Completes the visit and returns true if it is valid
    mutating func done() -> Bool {
        endUnixtime = Date().unixTime
        return isValid
    }
    
    /// Returns true if this visit lasted at least 0.5s and the endtime is valid
    var isValid: Bool { get {
        return endUnixtime > 0 && endUnixtime - startUnixtime > 500
    } }
    
}
