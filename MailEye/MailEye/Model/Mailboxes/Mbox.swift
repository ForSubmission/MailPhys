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

/// Represents a mailbox loaded from an mbox file
/// Parses a given mbox file by looking for all headers within it.
/// Stores results in NSRanges pointint to the underlying NSString.
class Mbox: Mailbox {
    
    // MARK: - Private fields
    
    /// They store the whole mbox
    private let nss: NSString
    private let mboxString: String
    private let headerMatches: [NSTextCheckingResult]
    
    // MARK: - Init
    
    /// errorHandler is a method that is called every time loading a message throws an error.
    /// returns nil if input url can't be read using macOSRoman or UTF-8 Encoding.
    init?(inUrl: URL) {
        
        let _string: String?
        
        do {
            _string = try String(contentsOf: inUrl, encoding: .utf8)
        } catch {
            do {
                _string = try String(contentsOf: inUrl, encoding: .macOSRoman)
            } catch {
                if #available(OSX 10.12, *) {
                    os_log("Error while loading mbox: %@", type: .error, error.localizedDescription)
                }
                return nil
            }
        }
        
        guard let string = _string else {
            return nil
        }
        
        self.mboxString = string
        self.nss = string as NSString
        
        do {
            self.headerMatches = try Mbox.parseHeaders(string)
            if headerMatches.count == 0 {
                return nil
            }
        } catch {
            return nil
        }
        
        // ready
        super.init(nOfMessages: headerMatches.count)
    }
    
    // MARK: - Overridden functions
    
    override func fetchMessage(atIndex: Int) throws -> Message {
        guard let header = self.headerMatches[atIndex].extract(mboxString, 0) else {
            throw Message.Error.noHeader
        }
        
        let contents = Mbox.parseContents(atIndex, headerMatches: self.headerMatches, nss: self.nss)
        
        return try Message(fromHeader: header, contents: contents)
    }
    
    override func fetchFullContents(atIndex: Int) -> String? {
        if let header = self.headerMatches[atIndex].extract(mboxString, 0) {
            let contents = Mbox.parseContents(atIndex, headerMatches: self.headerMatches, nss: self.nss)
            return header + "\n" + contents
        } else {
            return nil
        }
    }
    
    // MARK: - Static functions
    
    /// Parse all mail headers from the mbox (string).
    /// Should return a substring representing the header for each mail.
    static func parseHeaders(_ string: String) throws -> [NSTextCheckingResult] {
        let headerPat = "From (\\S+@\\S+\\.\\S+) ([a-zA-Z]{3}) ([a-zA-Z]{3}) (\\d{2}) ([\\d:]+) (\\d{4})\\n(.+\\n)+"
        let headerRegex = try NSRegularExpression(pattern: headerPat, options: [.useUnicodeWordBoundaries])
        
        // perform search and store results
        
        /// Regex result for headers, one per email
        return headerRegex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
    }
    
    /// Get full contents for the message at the given index
    static func parseContents(_ index: Int, headerMatches: [NSTextCheckingResult], nss: NSString) -> String {
        
        // If this is the last message, return everything from the end
        // of the last header
        if index == headerMatches.count - 1 {
            let start = headerMatches[index].range(at: 0).upperBound
            return nss.substring(from: start)
        }
        
        let start = headerMatches[index].range(at: 0).upperBound
        let end = headerMatches[index + 1].range(at: 0).lowerBound - 1
        let length = end - start
        let range = NSRange(location: start + 1, length: length)
        
        return nss.substring(with: range)
    }

}
