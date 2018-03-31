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

/// Represents a keyword in a message
struct Keyword: Codable, Equatable {
    
    /// Actual keyword. Should be lowercase.
    /// - Note: this should be hashed when encryption is on.
    let name: String
    
    /// Length of source (non-hashed) keyword
    let length: Int
    
    /// Duration of gaze every time this keyword was seen
    var gazeDurations: [Int]
    
    init(fromWord: String, gazeDuration: Int) {
        if AppSingleton.hashEverything {
            name = fromWord.md5
        } else {
            name = fromWord
        }
        length = fromWord.count
        gazeDurations = [gazeDuration]
    }
    
    mutating func add(gazeDuration: Int) {
        gazeDurations.append(gazeDuration)
    }
    
}

/// Two keywords are equal when they have the same name
func ==(lhs: Keyword, rhs: Keyword) -> Bool {
    return lhs.name == rhs.name
}
