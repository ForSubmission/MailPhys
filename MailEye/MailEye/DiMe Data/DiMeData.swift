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

/// Points to an endpoint, with the associated string used in the url for the request
enum DiMeEndpoint: String {
    case Event = "event"
    case InformationElement = "informationelement"
}

protocol DiMeData: Codable {
    
    /// Unique reference given by MailEye for the item
    var appId: String { get }
    
    /// This inform DiMe of which data class we are uploading and should be uploaded
    /// as @type. Used only for root types.
    /// e.g. `"@type": "Message"`
    var _type: String { get }
    
    /// Detailed data type according to the Semantic Desktop ontology:
    /// www.semanticdesktop.org/ontologies/2007/03/22/nfo
    /// e.g. `"type": "http://www.hiit.fi/ontologies/dime/#ScientificDocument"`
    var type: String { get }
    
}

extension DiMeData {
    /// Creates an appId from a message id.
    /// The id is "MailEye_" + md5 hash of original message id
    static func makeAppId(_ id: String) -> String {
        // it always uses the md5 of the id
        return "MailEye_\(id.md5)"
    }
}
