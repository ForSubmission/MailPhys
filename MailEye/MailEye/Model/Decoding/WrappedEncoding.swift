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

/// Encapsulates swift supported encodings and CFString encodings
enum WrappedEncoding {
    
    case swift(String.Encoding)
    case ns(UInt)
    
    var isUtf: Bool { get {
        switch self {
        case .swift(let swenc):
            return utfEncodings.contains(swenc)
        case .ns(let nsenc):
            return utfEncodings.map({$0.rawValue}).contains(nsenc)
        }
    } }
    
    var utfEncodings: [String.Encoding] { get {
        return [.utf8, .utf16, .utf32, .utf16BigEndian, .utf16LittleEndian,
                .utf32BigEndian, .utf32LittleEndian]
    } }

}

