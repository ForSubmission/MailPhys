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

/// Represents a chunk of a message, which could either be a full email,
/// or a part of a multipart message.
struct MessageChunk {
    /// body that should contain decoded text.
    let body: String?
    
    /// Original content type of message
    let contentType: ContentType
    
    /// True if this is an attachment or contains attachments
    private(set) var attachments = false
    
    /// Inits from a message or boundary header and a possible body
    /// Returns nil if the content type is unsupported (e.g. an attachment)
    /// - attention: Can throw Message.Error
    init(fromHeader: String, possibleBody: String, id: String) throws {
        // There are these supported body types
        
        // 1 - if Content-Type contains multipart, we get
        // * in boundary="*" and use that to split the message into parts.
        // we then check the contenty-type of each boundary until
        // we find text. If no text is found, we check if any
        // parts are multipart, split those into parts and
        // repeat until we find text
        
        // 2 - if content-type is text/plain or text/html we get
        // * in charset="*" and decode the whole body
        // the header should have Content-Transfer-Encoding: *,
        // telling us if it's base64, 7bit, quoted-printable
        
        // if there's no content type, assume 7bit with utf8
        guard let contentType = ContentType(fromHeader: fromHeader) else {
            self.body = possibleBody
            self.contentType = .plaintext(charset: "utf-8")
            return
        }
        
        self.contentType = contentType
        
        switch contentType {
        case .multipart(let boundary, let isAlternative):
            
            do {
                
                let chunks = try MessageChunk.split(chunk: possibleBody, boundary: boundary, id: id)
                
                if isAlternative {
                    // return the second chunk which is not empty (if it exists)
                    let filtered = chunks.filter() {$0.body != nil && !$0.body!.isEmpty}
                    guard filtered.count > 0 else {
                        throw Message.Error.cantReassemble(id: id, errorMessage: "Alternative message does not seem to have any valid parts")
                    }
                    // return second item if present, otherwise first
                    if filtered.count >= 2 {
                        self.body = filtered[1].body
                    } else {
                        self.body = filtered[0].body
                    }
                } else {
                    self.body = chunks.compactMap({$0.body}).joined(separator: "\n\n")
                    self.attachments = chunks.filter({$0.attachments}).count > 0
                }
                
            } catch {
                throw Message.Error.cantReassemble(id: id, errorMessage: error.localizedDescription)
            }
            
        case .plaintext(let charset):
            
            let transferEncoding = TransferEncoding(head: fromHeader) ?? .sevenBit
            do {
                self.body = try Message.bodyFromText(text: possibleBody, transferEncoding: transferEncoding, charset: charset)
            } catch {
                throw Message.Error.encodingError(id: id, errorMessage: error.localizedDescription)
            }
            
        case .html(let charset):
            
            let transferEncoding = TransferEncoding(head: fromHeader) ?? .sevenBit
            do {
                let string: String
                var alreadyDecoded = false
                if let charset = charset {
                    string = try Message.bodyFromText(text: possibleBody, transferEncoding: transferEncoding, charset: charset)
                    alreadyDecoded = true
                } else {
                    string = possibleBody
                }
                let htmlCharset = alreadyDecoded ? "utf-8" : charset ?? ""
                self.body = try string.htmlDecode(charset: htmlCharset)
            } catch {
                throw Message.Error.encodingError(id: id, errorMessage: error.localizedDescription)
            }
            
        case .unsupported(let ct, let name):
            
            // unsupported content types are interpreted as an attachment
            self.body = "Attachment: \(name) (\(ct))"
            self.attachments = true
            
        }
        
    }
}
