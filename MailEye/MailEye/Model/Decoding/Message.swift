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

/// Represents an message (e.g. e-mail) and all its metadata
struct Message {
    
    let subject: String
    let sender: String
    let senderName: String?
    let body: String
    let date: Date
    
    private(set) var containsAttachments = false
    
    /// Id of message
    let id: String
    
    /// Optionally specifies which message this replies to (IDs)
    let repliesTo: [String]?
    
    /// Optionally specifies references (IDs)
    let references: [String]?
    
    init(fromHeader: String, contents: String) throws {
        
        let fromMatches = matchesForRegex(pattern: "\\nFrom: ?\"?(.*?)\"?\\s*?<?([A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,})>?(?:\\n\\S|\\n\\n|\\n\\Z)", inString: fromHeader, extraOptions: [.caseInsensitive, .dotMatchesLineSeparators])
        
        let subjMatches = matchesForRegex(pattern: "\\nSubject:\\s*(.*?)\\n\\S", inString: fromHeader, extraOptions: .dotMatchesLineSeparators)
        // date may or may not begin with a 3-letter "day, ", e.g. "Tue, "
        let dateMatches = matchesForRegex(pattern: "\\nDate: (?:.{3}, )?(.+)\\n", inString: fromHeader)
        let idMatches = matchesForRegex(pattern: "\\nMessage-ID:\\s*<(.*?)>", inString: fromHeader, extraOptions: .caseInsensitive)

        // Group 1: sender
        // Group 2: subject
        // Group 3: date: 6 Mar 2017 11:00:19 +0200
        
        guard idMatches.count > 0 && idMatches[0].numberOfRanges > 1,
              let id = idMatches[0].extract(fromHeader, 1) else {
            throw Message.Error.noId
        }
        
        self.id = id
        
        guard fromMatches.count > 0 && fromMatches[0].numberOfRanges > 1 else {
            throw Message.Error.noSender(id: id)
        }
        
        guard dateMatches.count > 0 && dateMatches[0].numberOfRanges > 1 else {
            throw Message.Error.noDate(id: id)
        }
        
        do {
            self.repliesTo = try Message.parseList(listName: "In-Reply-To", header: fromHeader,  id: id)
        } catch Error.listParse(let id, let errorMessage) {
            if #available(OSX 10.12, *) {
                os_log("Error parsing in-reply-to list in %@: %@", type: .debug, id, errorMessage)
            }
            self.repliesTo = nil
        }
        
        do {
            self.references = try Message.parseList(listName: "References", header: fromHeader, id: id)
        } catch Error.listParse(let id, let errorMessage) {
            if #available(OSX 10.12, *) {
                os_log("Error parsing references list in %@: %@", type: .debug, id, errorMessage)
            }
            self.references = nil
        }
        
        // second range is email address
        guard let sender = fromMatches[0].extract(fromHeader, 2) else {
            throw Error.noSender(id: id)
        }
        
        self.sender = sender
        
        // first range is name, if present
        if let _senderName = fromMatches[0].extract(fromHeader, 1),
            !_senderName.isEmpty {
            if let decodedName = try Message.decodeInlinedItem(_senderName) {
                self.senderName = decodedName
            } else {
                self.senderName = _senderName
            }
        } else {
            self.senderName = nil
        }
        
        // if there's a subject, try to decode it from quoted-printable, if it makes sense
        if subjMatches.count > 0 && subjMatches[0].numberOfRanges > 1,
           let possibleSubject = subjMatches[0].extract(fromHeader, 1) {
            if let decodedSubject = try Message.decodeInlinedItem(possibleSubject) {
                subject = decodedSubject.noLineBreakWhiteSpace
            } else {
                subject = possibleSubject.noLineBreakWhiteSpace
            }
        } else {
            subject = "<no subject>"
        }
        
        guard var dateString = dateMatches[0].extract(fromHeader, 1) else {
            throw Error.noDate(id: id)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM y HH:mm:ss Z"
        
        // if there's somthing in parentheses in the date,
        // for example (UTC), skip everything until before '('
        if let parI = dateString.index(of: "(") {
            let beforeI = dateString.index(before: parI)
            dateString = String(dateString[..<beforeI])
        }
        
        guard let date = dateFormatter.date(from: dateString) else {
            throw Message.Error.invalidDate(id: id)
        }
        
        self.date = date
        
        let mainChunk = try MessageChunk(fromHeader: fromHeader, possibleBody: contents, id: self.id)
        self.containsAttachments = mainChunk.attachments
        
        guard let body = mainChunk.body?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            switch mainChunk.contentType {
            case .unsupported(let cteString):
                throw Message.Error.unsupportedCT(id: id, ctString: cteString.cteString)
            default:
                fatalError("We should never get here")
            }
        }
        
        self.body = body
                
    }
    
    init(fromCurlMessage: CurlMessage) throws {
        guard let fullContents = fromCurlMessage.fullContents else {
            throw Error.noData
        }
        let fixedContents = fullContents.replacingOccurrences(of: "\r\n", with: "\n")
        if let r = fixedContents.range(of: "\n\n") {
            let header = String(fixedContents[..<r.lowerBound])
            let contents = String(fixedContents[r.upperBound...])
            try self.init(fromHeader: header, contents: contents)
        } else {
            throw Error.curlFail
        }
    }
    
    init(placeholderForError error: Error, fullContents: String) {
        self.subject = error.localizedDescription
        self.body = fullContents
        self.id = Constants.failedMessageId
        self.sender = self.id
        self.senderName = nil
        self.date = Date()
        self.repliesTo = nil
        self.references = nil
    }
    
    // MARK: - Static

    // Extracts body from a stringencoding and a charset
    static func bodyFromText(text: String, transferEncoding: TransferEncoding, charset: String) throws -> String {
        let stringEncoding = try charset.decodeCharset()
        switch transferEncoding {
        case .base64:
            return String(fromBase64string: text, encoding: stringEncoding) ?? "COULDN'T DECODE\n\n" + text
        case .quotedPrintable:
            //if stringEncoding == .utf8, let decoded = text.decodeQuotedPrintable_regex() {
            //    return decoded
            if stringEncoding.isUtf, let decoded = text.decodeQuotedPrintable_percent() {
                return decoded
            } else {
                return text.decodeQuotedPrintable_nonUtf(encoding: stringEncoding)
            }
        case .binary:
            // for now, we just return the string as-is.
            return text
        case .sevenBit, .eightBit:
            // do nothing for 7 and 8 bit, it should already be ok
            return text
        }
    }
    
    /// Gets a list of IDs from a header.
    /// Used for In-Reply-To and References lists of IDs.
    /// Returns nil if there's no such list.
    static func parseList(listName: String, header: String, id: String) throws -> [String]? {
        
        // first get the whole list, which is everything until a newline which is not followed by whitespace
        let wholeListMatches = matchesForRegex(pattern: "\\n\(listName):(.*?)\\n(?:\\S|\\n)", inString: header, extraOptions: [.caseInsensitive, .dotMatchesLineSeparators])
        
        if wholeListMatches.count == 0 {
            return nil  // this list is not relevant but this is not an error
        }
        
        // if there's more than one match, that's weird
        guard wholeListMatches.count == 1 else {
            throw Error.listParse(id: id, errorMessage: "More than one match found for \(listName)")
        }
        
        guard let wholeList = wholeListMatches[0].extract(header, 1) else {
            throw Error.listParse(id: id, errorMessage: "Nothing captured overall for \(listName)")
        }
        
        // now get individual items (there must be at least one, get everything between <>)
        let itemMatches = matchesForRegex(pattern: "(?:<(.*?)>)+", inString: wholeList, extraOptions: [.dotMatchesLineSeparators])
        
        guard itemMatches.count > 0 else {
            throw Error.listParse(id: id, errorMessage: "Nothing captured within list for \(listName)")
        }
        
        // return group 1 (id) in all matches, skip nils and remove tabs and spaces
        return itemMatches.compactMap({$0.extract(wholeList, 1)?.replacingOccurrences(of: "\t", with: "").replacingOccurrences(of: " ", with: "")})
        
    }
    
    /// Attempts to decode an inline encoded item (e.g. subject line).
    /// An encoded item looks like this:
    /// =?EEEE?L?abcdefgh?=
    /// it could be one or more lines, where EEEE is char encoding (e.g. utf-8)
    /// and l a letter specifiying data encoding (Q for quoted printable
    /// or B for base 64.
    static func decodeInlinedItem(_ string: String) throws -> String? {
        // check for the =?UTF-8?Q? ... ?= pattern (example)
        let pattern = "=\\?(\\S+)\\?(\\w?)\\?(.*?)\\?="
        let qResult = matchesForRegex(pattern: pattern, inString: string)
        
        // if this was really encoded, we should have 3 (+ 1) ranges for each match
        // 1 : charset (e.g. utf-8)
        // 2 : letter for transfer encoding (Q for quoted printable, B for base64)
        // 3 : the data
        guard qResult.count > 0 && qResult[0].numberOfRanges == 4 else {
            return nil
        }
        
        // concatenate all third ranges using the first and second as data descriptors
        let concatanated = try qResult.reduce("") {
            res, item in
            
            let charset = try (item.extract(string, 1) ?? "").decodeCharset()
            guard let L = item.extract(string, 2) else {
                return ""
            }
            guard let chunk = item.extract(string, 3) else {
                return ""
            }
            if L.uppercased() == "B" {
                // base 64
                
                if let s = String(fromBase64string: chunk, encoding: charset) {
                    return res + s
                } else {
                    return res + ""
                }
            } else if L.uppercased() == "Q" {
                // quoted printable.
                // decode using regex if utf8, if not use the other decoder
                let retVal = charset.isUtf ? res + (chunk.decodeQuotedPrintable_percent() ?? string) : res + chunk.decodeQuotedPrintable_nonUtf(encoding: charset)
                // remove underscores
                return retVal.replacingOccurrences(of: "_", with: " ")
            } else {
                return res + ""
            }
        }
        
        guard !concatanated.isEmpty else {
            return nil
        }
        
        return concatanated
    }
    
}

extension Message {
    
    enum Error: Swift.Error, LocalizedError {
        
        var errorDescription: String? { get {
            var messageId = "<no id>"
            let message: String
            var post = ""
            
            switch self {
            case .noDate(let id):
                message = NSLocalizedString("No date found in header", comment: "No date was found in header")
                messageId = id
            case .noSender(let id):
                message = NSLocalizedString("No sender found in header", comment: "No sender(s) was(were) found in header")
                messageId = id
            case .curlFail:
                message = NSLocalizedString("Splitting curl message failed", comment: "Splitting curl message failed")
            case .noId:
                message = NSLocalizedString("No id found in header", comment: "Message without mandatory id string")
            case .invalidDate(let id):
                message = NSLocalizedString("Invalid date found in header", comment: "Message with invalid date")
                messageId = id
            case .missingTE(let id):
                message = NSLocalizedString("Missing transfer encoding", comment: "Message did not seem to contain a transfer encoding")
                messageId = id
            case .unsupportedCT(let id, let ctString):
                message = NSLocalizedString("Unrecognized content type: ", comment: "Message has an unrecognized Content Type")
                messageId = id
                post = ctString
            case .cantReassemble(let id, let errorMessage):
                message = NSLocalizedString("Can't reassemble split message: ", comment: "Message can't be reassembled, specific error follows")
                messageId = id
                post = errorMessage
            case .encodingError(let id, let errorMessage):
                message = NSLocalizedString("Can't decode string: ", comment: "Message can't be decoded, specific error follows")
                messageId = id
                post = errorMessage
            case .noHeader:
                message = NSLocalizedString("No message header found (this should never happen)", comment: "Message doesn't have header")
            case .listParse(let id, let errorMessage):
                message = NSLocalizedString("Failed to parse list properly: ", comment: "Can't parse list, detailed reason follow")
                messageId = id
                post = errorMessage
            case .noData:
                message = NSLocalizedString("No data found", comment: "No data found when creating message")
            }
            
            return messageId + ": \(message)" + post
            } }
        
        case noDate(id: String)
        case noId
        case noHeader
        case curlFail
        case noSender(id: String)
        case missingTE(id: String)
        case invalidDate(id: String)
        case unsupportedCT(id: String, ctString: String)
        case cantReassemble(id: String, errorMessage: String)
        case encodingError(id: String, errorMessage: String)
        case listParse(id: String, errorMessage: String)
        case noData
    }
    
}
