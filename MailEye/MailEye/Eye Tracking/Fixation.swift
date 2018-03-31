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

/// Represents a fixation detected by an eye tracker.
/// Origin of fixation events is on top left of screen.
struct FixationEvent: Equatable, FloatDictInitializable, Codable {
    var startTime: Int
    var endTime: Int
    /// Duration of fixation in nanoseconds.
    var duration: Int
    /// Position of fixation, in pixels. Origin on left.
    var positionX: Double
    /// Position of fixation, in pixels. Origin on top.
    var positionY: Double
    /// Pupil size (if known)
    var pupilSize: Double?
    /// Unix time representing when this fixation was captured
    var unixtime: Int
    
    /// Trivial initializer
    init(startTime: Int, endTime: Int, duration: Int, positionX: Double, positionY: Double, unixtime: Int, pupilSize: Double? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.positionX = positionX
        self.positionY = positionY
        self.unixtime = unixtime
        self.pupilSize = pupilSize
    }
    
    /// Initializes from a dict (for LSL interfaces)
    init?(floatDict dict: [String: Float]) {
        // if eye corresponds to dominant, create fixation, otherwise return nil
        let eye = Eye(rawValue: Int(dict["eye"]!))!
        guard eye == AppSingleton.dominantEye else {
            return nil
        }
    
        self.startTime = Int(dict["startTime"]!)
        self.duration = Int(dict["duration"]!)
        self.endTime = Int(dict["endTime"]!)
        self.positionX = Double(dict["positionX"]!)
        self.positionY = Double(dict["positionY"]!)
        self.unixtime = Int(dict["marcotime"]!) + 1446909066675
    }

}

/// Two fixations are the same if all their properties are equal (except for pupil sizes)
func == (lhs: FixationEvent, rhs: FixationEvent) -> Bool {
    return lhs.startTime == rhs.startTime &&
           lhs.endTime == rhs.endTime &&
           lhs.duration == rhs.duration &&
           lhs.positionX == rhs.positionX &&
           lhs.positionY == rhs.positionY &&
           lhs.unixtime == rhs.unixtime
}
