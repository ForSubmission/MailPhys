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

extension Dictionary where Key == String, Value == Array<Event> {
    
    /// Adds a visit to a dictionary of strings, e.g. that uses
    /// message IDs to index data
    mutating func appendIfExists(k: String, v: Event) {
        if var vs = self[k] {
            vs.append(v)
            self[k] = vs
        } else {
            self[k] = [v]
        }
    }
    
}

extension Dictionary where Key == String, Value == Array<Selection> {
    
    /// Adds a selection to a dictionary of strings, e.g. that uses
    /// message IDs to index data
    mutating func appendIfExists(k: String, s: Selection) {
        if var vs = self[k] {
            vs.append(s)
            self[k] = vs
        } else {
            self[k] = [s]
        }
    }
    
}

extension Dictionary where Key == String, Value == Dictionary<String, Array<EyeDatum>> {
    
    /// Adds a fixation box entry to a dictionary of strings, e.g. that uses
    /// message IDs to index data
    mutating func addDatumIfExists(k: String, box: FixationBox, d: EyeDatum) {
        if var vs = self[k] {
            vs.addDatum(box: box, datum: d)
            self[k] = vs
        } else {
            self[k] = EyeData.empty
            self[k]!.addDatum(box: box, datum: d)
        }
    }

}

extension Dictionary where Key == String, Value == Array<Keyword> {
    
    /// Adds a keyword to an index that uses strings (e.g. message IDs) as keys.
    /// If the keyword is already present, adds the gaze duration to the existing entry.
    /// If its not present, adds the keyword to the array of keywords.
    /// - Note: kw must have only one gaze duration
    mutating func addKeywordIfExists(k: String, kw: Keyword) {
        
        // make sure there is only one gaze duration in input. if not, throw error
        guard kw.gazeDurations.count == 1 else {
            fatalError("There must be only one gaze duration in input keyword")
        }
        
        // make sure we assign something when done
        let assignee: [Keyword]
        defer {
            self[k] = assignee
        }
        
        if var kws = self[k] {
            // check if entry contains keyword already, if so add gaze duration
            if let kwi = kws.index(of: kw) {
                var updated = kws[kwi]
                updated.add(gazeDuration: kw.gazeDurations[0])
                kws[kwi] = updated
                assignee = kws
            } else {
                // if not, create new entry in keyword array
                kws.append(kw)
                assignee = kws
            }
        } else {
            // entry for message doesn't exist, create keyword array with one entry
            assignee = [kw]
        }
    }
    
}

