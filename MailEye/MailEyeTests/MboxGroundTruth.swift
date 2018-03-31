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

struct MboxGroundTruth {
    
    let fileName: String
    let name: String
    
    /// Every key refers to an email in the mbox, and the associated array contains strings
    /// that SHOULD be present in the body of the given email
    let shouldContain: [Int: [String]]
    
    /// Same as above but for words contained within subjects of emails
    let subjectShouldContain: [Int: [String]]
    
    /// Every key refers to an email in the mbox, and the associated array contains strings
    /// that SHOULD NOT be present in the body of the given email
    let shouldNotContain: [Int: [String]]
    
    /// Same as above but for words contained within subjects of emails
    let subjectShouldNotContain: [Int: [String]]
    
    /// The name (not address) of the sender must be this, for the given message index
    let nameMustBe: [Int: String]
    
    var url: URL { get {
        return Bundle(for: PublicTestData.self).url(forResource: fileName, withExtension: "")!
        }}
    
}
