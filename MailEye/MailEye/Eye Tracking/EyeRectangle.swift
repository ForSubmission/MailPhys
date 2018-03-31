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

/// Represents a box sent to the eye tracking analysis algo
struct EyeRectangle: Codable {
    
    /// Timestamp representing when this chunk of data was collected
    let unixt: Int
    
    /// Distance from screen when this eyerect was created
    fileprivate(set) var screenDistance: Double = 600.0
    
    /// Origin of this rect in page space
    fileprivate(set) var origin: NSPoint
    
    /// Size of this rect in page space
    fileprivate(set) var size: NSSize
    
    /// X coordinates in rectangle's space
    fileprivate(set) var Xs: [Double]
    
    /// Y coordinates in rectangle's space
    fileprivate(set) var Ys: [Double]
    
    /// Fixation durations
    fileprivate(set) var durations: [Int]
    
    /// Index (from 0) of page in which this rect appeared
    let pageIndex: Int
    
    let scaleFactor: Double

}
