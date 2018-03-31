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

import Cocoa

/// A person is represented by this struct (not a class)
struct Person: Codable {
    
    // MARK: - Required fields
    
    fileprivate(set) var firstName: String
    fileprivate(set) var lastName: String
    fileprivate(set) var middleNames: [String]
    fileprivate(set) var emailAccount: String?
    
    /// Returns the name in a string separated by spaces, such as "FistName MiddleName1 MiddleName2 LastName"
    var description: String { get {
        var outVal = firstName + " "
        if middleNames.count > 0 {
            for midName in middleNames {
                outVal += midName + " "
            }
        }
        outVal += lastName
        return outVal
        } }
    
    // MARK: - Init
    
    /// Generates a person from a string. If there is a comma in the string, it is assumed that the first name after the comma, otherwise first name is the first non-whitespace separated string, and last name is the last. Middle names are assumed to all come after the first name if there was a comma, between first and last if there is no comma.
    /// **Fails (returns nil) if the string could not be parsed.**
    init?(fromString string: String, email: String? = nil) {
        
        middleNames = [String]()
        emailAccount = email
        
        if string.contains(",") {
            let spl = string.split(separator: ",", maxSplits: 10, omittingEmptySubsequences: true).map({String($0)})
            if spl.count == 2 {
                self.lastName = spl[0]
                
                // check if there are middle names in the following part
                if spl[1].contains(" ") {
                    var resplitted = spl[1].split(separator: ",", maxSplits: 10, omittingEmptySubsequences: true).map({String($0)})
                    self.firstName = resplitted.remove(at: 0)
                    if resplitted.count > 0 {
                        for remName in resplitted {
                            middleNames.append(remName)
                        }
                    }
                }
                else {
                    self.firstName = spl[1]
                }
            } else {
                return nil
            }
        } else {
            let spl = string.split(separator: " ", maxSplits: 10, omittingEmptySubsequences: true).map({String($0)})
            if spl.count >= 2 {
                self.firstName = spl.first!
                self.lastName = spl.last!
                if spl.count > 2 {
                    for i in 1..<spl.count - 1 {
                        middleNames.append(spl[i])
                    }
                }
            } else {
                return nil
            }
        }
        
    }
    
    /// Creates a preson from crossref's json's ["message"]["author"] result.
    /// Crossref has an array of dicts with "given", "family" keys.
    /// "family" values can contain middle names separated by " "
//    init?(fromCrossRef json: JSON) {
//        super.init()
//        guard let fnamesS = json["given"].string, let lname = json["family"].string,
//              var fnames = fnamesS.split(" ")
//              , fnames.count >= 1 else {
//                return nil
//        }
//        self.firstName = fnames.remove(at: 0)
//        self.lastName = lname
//        self.middleNames = fnames
//    }
    
}
