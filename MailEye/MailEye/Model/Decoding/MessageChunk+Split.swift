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

extension MessageChunk {
    
    enum SplitError: Swift.Error, LocalizedError {
        var errorDescription: String? { get {
            switch self {
            case .noBoundary:
                return NSLocalizedString("Could not find a boundary", comment: "Error while splitting message")
            case .noData:
                return NSLocalizedString("Could not find any data", comment: "Error while splitting message")
            case .noMatches:
                return NSLocalizedString("Could not find any matches", comment: "Error while splitting message")
            case .noHeader:
                return NSLocalizedString("Could not find header", comment: "Error while splitting message")
            case .noBody:
                return NSLocalizedString("Could not find body", comment: "Error while splitting message")
            }
            } }
        
        case noBoundary
        case noHeader
        case noMatches
        case noData
        case noBody
    }
    
    /// Splits a message into parts (or a part into multiple parts).
    /// - attention: throws `SplitError`
    static func split(chunk: String, boundary: String, id: String) throws -> [MessageChunk] {
        
        /// the part header starts with a boundary, which may or may not
        /// be surrounded by -- (it is affixed with -- if it's the end of message
        /// boundary)
        let escapedBoundary = NSRegularExpression.escapedPattern(for: boundary)
        let pattern = "(?:--)*\(escapedBoundary)(?:--)*(.*?)\\n\\n"
        
        let boundaryMatches = matchesForRegex(pattern: pattern, inString: chunk, extraOptions: [.dotMatchesLineSeparators])
        
        guard boundaryMatches.count > 0 else {
            throw SplitError.noBoundary
        }
        
        var retVal = [MessageChunk]()
        
        for matchI in 0..<boundaryMatches.count {
            
            let match = boundaryMatches[matchI]
            
            // there must be at least one match, otherwise our
            // pattern was wrong
            guard match.numberOfRanges > 1 else {
                throw SplitError.noMatches
            }
            
            // we stop when the current match has two characters (there
            // will be no body following)
            if match.range(at: 1).length == 2 {
                break
            }
            
            guard let headersub = chunk.substring(nsRange: match.range(at: 0)) else {
                throw SplitError.noMatches
            }
            
            let header = String(headersub)
            
            let start = match.range(at: 0).length + match.range(at: 0).location
            let end: Int
            
            // body is until start of next match, or until
            // end if there's no next match
            
            if matchI + 1 < boundaryMatches.count {
                // get range until next match
                
                end = boundaryMatches[matchI + 1].range(at: 0).location - 1
            } else {
                // get range until end
                
                end = chunk.count
            }
            
            let nsr = NSRange(location: start, length: end-start)
            
            guard let bodysub = chunk.substring(nsRange: nsr) else {
                throw SplitError.noBody
            }
            
            var possibleBody = String(bodysub)
            
            // terminate body before --boundary--, if present
            if let terminatorRange = possibleBody.range(of: "--\(boundary)--") {
                possibleBody = String(possibleBody[..<terminatorRange.lowerBound])
            }
            
            let chunk = try MessageChunk(fromHeader: header, possibleBody: possibleBody, id: id)
            retVal.append(chunk)
            
        }
        
        return retVal
    }
    
}
