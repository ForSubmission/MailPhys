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

/// Facilitates conversion to the internal Message class to a struct
/// that can be submitted to DiMe
struct DiMeMessage: DiMeData {
    
    enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case appId
        case type
        case plainTextContent
        case subject
        case fromString
        case from
    }

    // MARK: - Fields
    
    var appId: String
    
    var _type: String = "Message"
    
    var type: String = "http://www.hiit.fi/ontologies/dime/#Message"
    
    var plainTextContent: String
    
    var subject: String
    
    let fromString: String
    
    let from: Person?
    
//    let toString: String
//
//    let to: [Person]
//
//    let ccString: String
//
//    let cc: [Person]
    
    // MARK: - Init
    
    init(fromMessage message: Message) {
        self.appId = DiMeMessage.makeAppId(message.id)
        self.plainTextContent = message.body
        self.subject = message.subject
        self.fromString = message.senderName ?? message.sender
        if let sn = message.senderName, let p = Person(fromString: sn, email: message.sender) {
            self.from = p
        } else {
            self.from = nil
        }
    }
    
}
