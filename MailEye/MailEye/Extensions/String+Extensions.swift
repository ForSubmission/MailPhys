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
import Cocoa
import WebKit

let stringWebPreferences: WebPreferences = {
    let prefs = WebPreferences()
    prefs.cacheModel = .documentViewer
    prefs.usesPageCache = false
    prefs.allowsAnimatedImages = false
    prefs.suppressesIncrementalRendering = true
    prefs.loadsImagesAutomatically = false
    prefs.arePlugInsEnabled = false
    prefs.isJavaEnabled = false
    prefs.isJavaScriptEnabled = false
    prefs.privateBrowsingEnabled = true
    return prefs
}()

enum StringDecodingError: Swift.Error, LocalizedError {
    
    var errorDescription: String? { get {
        let message: String
        var post: String = ""
        switch self {
        case .unrecognizedCharset(let charset):
            message = NSLocalizedString("Encoding not recognised: ", comment: "String encoding was not recognized, charset string follows")
            post = charset
        case .unsupportedCharset(let charset):
            message = NSLocalizedString("Encoding not supported: ", comment: "String encoding is not supported, charset string follows")
            post = charset
        case .htmlDecodingError:
            message = NSLocalizedString("Can't convert html to string", comment: "String can't converted to html and back")
        case .outOfRange(let input, let nsrange):
            message = NSLocalizedString("String parsing out of range: ", comment: "String can't was given an invalid nsrange, string and range follow")
            post = "string: \(input), range: \(nsrange)"
        }
        return message + post
        
    } }

    case unrecognizedCharset(charset: String)
    case unsupportedCharset(charset: String)
    case outOfRange(input: String, nsRange: NSRange)
    case htmlDecodingError
}

extension String {
    
    /// Returns SHA1 digest for this string
    var sha1: String { get {
        let data = self.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1((data as NSData).bytes, CC_LONG(data.count), &digest)
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined(separator: "")
    } }
    
    /// Returns MD5 digest for this string
    var md5: String { get {
        let data = self.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5((data as NSData).bytes, CC_LONG(data.count), &digest)
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined(separator: "")
    } }
    
    /// Version for previews, with less line breaks
    var previewVersion: String { get {
        var split = self.components(separatedBy: .newlines)
        split = split.filter({$0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count >= 1})
        if split.count >= 2 {
            return split[0] + "\n" + split[1]
        } else if split.count == 1 {
            return split[0]
        } else {
            return " "
        }
    } }
    
    /// Version with =\n replaced with space
    var noPEBreaks: String { get {
        return self.replacingOccurrences(of: "=\r\n", with: " ")
                   .replacingOccurrences(of: "=\n", with: " ")
    } }
    
    /// Version with linebreak + whitespace replaced with just space
    var noLineBreakWhiteSpace: String { get {
        return self.replacingOccurrences(of: "\n\t", with: " ").replacingOccurrences(of: "\n ", with: " ").replacingOccurrences(of: "\t", with: " ").replacingOccurrences(of: "\n", with: " ")
        }}
    
    /// Version with all windows and unix line breaks replaced with spaces
    var noLineBreaks: String { get {
        return self.replacingOccurrences(of: "\r\n", with: " ").replacingOccurrences(of: "\n", with: " ")
    } }
    
    init?(fromBase64string: String, encoding: WrappedEncoding) {
        
        let inString: String
        
        // chop everything until double break
        if let boundRange = fromBase64string.range(of: "\r\n\r\n") {
            inString = String(fromBase64string[..<boundRange.lowerBound])
        } else if let boundRange = fromBase64string.range(of: "\n\n") {
            inString = String(fromBase64string[..<boundRange.lowerBound])
        } else {
            inString = fromBase64string
        }
        
        if let data = Data(base64Encoded: inString, options: .ignoreUnknownCharacters) {
            
            switch(encoding) {
            case .swift(let swenc):
                if let outString = String(data: data, encoding: swenc) {
                    self = outString
                } else {
                    return nil
                }
            case .ns(let nsenc):
                if let nsString = NSString(data: data, encoding: nsenc) {
                    self = nsString as String
                } else {
                    return nil
                }
            }
           
        } else {
            return nil
        }
    }
    
    /// if this is a charset string (e.g. utf-8) return
    /// its equivalent encoding. If not recognised
    /// throws a `StringDecodingError`
    func decodeCharset() throws -> WrappedEncoding {
        switch self.lowercased() {
        case "utf-8", "", "\"\"", "\"":
            return .swift(.utf8)
        case "utf-16":
            return .swift(.utf16)
        case "utf-32":
            return .swift(.utf32)
        case "us-ascii":
            return .swift(.ascii)
        case "iso-8859-1":
            return .swift(.isoLatin1)
        case "iso-8859-2":
            return .swift(.isoLatin2)
        case "windows-1250", "cp1250":
            return .swift(.windowsCP1250)
        case "windows-1251", "cp1251":
            return .swift(.windowsCP1251)
        case "windows-1252", "cp1252":
            return .swift(.windowsCP1252)
        case "windows-1253", "cp1253":
            return .swift(.windowsCP1253)
        case "windows-1254", "cp1254":
            return .swift(.windowsCP1254)
        default:
            let cfsenc = CFStringConvertIANACharSetNameToEncoding(self as CFString)
            if cfsenc != kCFStringEncodingInvalidId {
                return .ns(CFStringConvertEncodingToNSStringEncoding(cfsenc))
            } else {
                throw StringDecodingError.unrecognizedCharset(charset: self)
            }
        }
    }
    
    /// Converts a string from html to just the contents of the html
    func htmlDecode(charset: String) throws -> String {

        let _data: Data?
        
        let str = self.decodeQuotedPrintable_percent() ?? self
        
        switch try charset.decodeCharset() {
        case .swift(let swenc):
            _data = str.data(using: swenc)
        case .ns(let nsenc):
            _data = (str as NSString).data(using: nsenc, allowLossyConversion: true)
        }
        
        guard let data = _data else {
            throw StringDecodingError.htmlDecodingError
        }
        
        let attString = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue, .timeout: 2.0, .webPreferences: stringWebPreferences], documentAttributes: nil)
        
        return attString.string
    }
    
    var nOfLineBreaks: Int { get {
        return self.components(separatedBy: .newlines).count - 1
    } }
    
    func substring(nsRange: NSRange) -> Substring? {
        guard nsRange.location >= 0, nsRange.length >= 0,
            let r = Range(nsRange, in: self) else {
            return nil
        }
        return self[r]
    }
        
    /// Decodes quoted printable by doing some manual substitutions, assuming utf8
    func decodeQuotedPrintable_percent() -> String? {
        return self
            .replacingOccurrences(of: "=\r\n", with: "")
            .replacingOccurrences(of: "=\n", with: "")
            .replacingOccurrences(of: "%", with: "%25")
            .replacingOccurrences(of: "=", with: "%")
            .removingPercentEncoding
    }
    
    /// Allows initialization with one byte and wrapped encoding
    init?(byte: UInt8, encoding: WrappedEncoding) {
        switch encoding {
        case .swift(let swenc):
            if let rv = String(bytes: [byte], encoding: swenc) {
                self = rv
            } else {
                return nil
            }
        case .ns(let nsenc):
            if let rv = NSString(bytes: [byte], length: 1, encoding: nsenc) {
                self = rv as String
            } else {
                return nil
            }
        }
    }
    
    /// Decode quoted printable for non-utf encoding
    /// e.g. good for latin1
    func decodeQuotedPrintable_nonUtf(encoding: WrappedEncoding) -> String {
        
        guard !encoding.isUtf else {
            if #available(OSX 10.12, *) {
                os_log("Should not try to use nonutf decoding for utf encoded quoted printables", type: .error)
            }
            return self
        }
        
        var output = self
            .replacingOccurrences(of: "=\r\n", with: "")
            .replacingOccurrences(of: "=\n", with: "")
        
        var seekRange = output.startIndex ..< output.endIndex
        while let eqRange = output.range(of: "=", range: seekRange),
            let bEnd = output.index(eqRange.lowerBound, offsetBy: 3, limitedBy: output.endIndex)
        {
            
            let bString = output[eqRange.upperBound..<bEnd]
            
            guard let byte = UInt8(bString, radix: 16),
                let char = String(byte: byte, encoding: encoding) else {
                    
                    seekRange = bEnd ..< output.endIndex
                    continue
            }
            
            output.replaceSubrange(eqRange.lowerBound..<bEnd, with: char)
            seekRange = eqRange.lowerBound ..< output.endIndex
        }
        
        return output
        
    }

}
