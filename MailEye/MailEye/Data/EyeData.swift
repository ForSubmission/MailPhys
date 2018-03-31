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
import os.log

/// Identifies where a fixation can be detected
enum FixationBox: String, CustomStringConvertible, Codable {
    
    var description: String { get {
        return self.rawValue
    } }
    
    case thread
    case reference
    case header
    case body
    
}

typealias EyeData = [String: [EyeDatum]]

extension Dictionary where Key == String, Value == Array<EyeDatum> {
    static var empty: EyeData { get {
        return [FixationBox.body.rawValue: [EyeDatum](),
                FixationBox.header.rawValue: [EyeDatum](),
                FixationBox.reference.rawValue: [EyeDatum](),
                FixationBox.thread.rawValue: [EyeDatum]()]
    } }
    
    /// Adds eye data to a fixation box.
    /// - Attention: does nothing if data was not previously
    /// created using EyeData.empty.
    mutating func addDatum(box: FixationBox, datum: EyeDatum) {
        guard var data = self[box.rawValue] else {
            if #available(OSX 10.12, *) {
                os_log("Did not find any previous eye data to which append datum", type: .error)
            }
            return
        }
        
        data.append(datum)
        self[box.rawValue] = data
    }
    
    /// Unites two sets of EyeData.
    /// - Attention: does nothing if data was not previously
    /// created using EyeData.empty.
    mutating func unite(otherData: EyeData) {
        for (boxKey, newData) in otherData {
            guard var data = self[boxKey] else {
                if #available(OSX 10.12, *) {
                    os_log("Did not find any previous eye data to which unite data", type: .error)
                }
                continue
            }
            
            data.append(contentsOf: newData)
            self[boxKey] = data
        }
    }
}

/// Encodes fixations within eye boxes for export
struct EyeDatum: Codable {
    var x: Double
    var y: Double
    var duration: Int
    var unixtime: Int
}
