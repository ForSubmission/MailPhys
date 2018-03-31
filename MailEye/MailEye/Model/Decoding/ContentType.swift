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

/// Content-Type: a string tells us
/// about this message or its part (e.g. `MessageChunk`), so we know if it's a single message
/// or a multipart message or if its plain text or html text.
enum ContentType {
    /// Multipart message or part, the associated string is the boundary
    case multipart(boundary: String, isAlternative: Bool)
    /// Html, this needs to be decoded and converted to string
    /// The associated string contains the charset (can be nil)
    case html(charset: String?)
    /// Plain text message or part, the associated string is the charset
    case plaintext(charset: String)
    /// Unsupported chunk, the associated string is the whole content type
    /// string, so we can debug
    case unsupported(cteString: String, name: String)
    
    /// Creates itself from a full header or part header. Returns nil if the content-type
    /// string couldn't be found
    /// Can throw a StringDecodingError
    init?(fromHeader header: String) {
        
        // parse content type string
        // (?:\n\s.*)* is added to group (without capture) zero or more
        // newline+whitespace+anything groups, since header entries could
        // be split across multiple lines when the next line starts with tab or space
        let contentTypeMatches = matchesForRegex(pattern: "\nContent-[Tt]ype: (.*);.*(?:\\n\\s.*)*(?:$|\\n)", inString: header)
        
        guard contentTypeMatches.count > 0 && contentTypeMatches[0].numberOfRanges > 1 else {
            // special case for html with no specific charset
            if header.contains("text/html") {
                self = .html(charset: nil)
                return
            } else {
                return nil
            }
        }
        
        let ctRange = contentTypeMatches[0].range(at: 1)
        // ctString is the full match, which contains all info
        let ctString = String(header.substring(nsRange: contentTypeMatches[0].range(at: 0)) ?? "" )
        let ct = String(header.substring(nsRange: ctRange) ?? "").lowercased()
        
        if ct.contains("multipart") {
            
            guard let boundary = extractHeaderParameter(fromCTstring: ctString, parameter: "boundary") else {
                if #available(OSX 10.12, *) {
                    os_log("Could not get boundary from: %@", type: .error, ct)
                }
                return nil
            }
            
            let isAlternative = ct.contains("multipart/alternative")
            
            self = .multipart(boundary: boundary, isAlternative: isAlternative)
            
        } else if ct.contains("text/plain") {
            
            if let charset = extractHeaderParameter(fromCTstring: ctString, parameter: "charset") {
                self = .plaintext(charset: charset)
            } else {
                if #available(OSX 10.12, *) {
                    os_log("Could not get charset from: %@, defaulting to utf", type: .fault, ct)
                }
                self = .plaintext(charset: "utf-8")
            }
            
            
        } else if ct.contains("text/html") {
            
            if let charset = extractHeaderParameter(fromCTstring: ctString, parameter: "charset") {
                self = .html(charset: charset)
            } else {
                if #available(OSX 10.12, *) {
                    os_log("Could not get charset from: %@, defaulting to utf", type: .fault, ct)
                }
                self = .html(charset: "utf-8")
            }

        } else {
            // for name, match everything except " between name="HERE"
            let nameMatches = matchesForRegex(pattern: "name=\"([^\"]+)\"", inString: header, extraOptions: [.dotMatchesLineSeparators])
            let name: String
            if nameMatches.count > 0 && nameMatches[0].numberOfRanges > 1 {
                let nameRange = nameMatches[0].range(at: 1)
                name = String(header.substring(nsRange: nameRange) ?? "" ).noLineBreaks
            } else {
                name = ""
            }
            self = .unsupported(cteString: ct, name: name)
        }
    }
    
}
