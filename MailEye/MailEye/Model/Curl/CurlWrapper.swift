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

class CurlWrapper {
    
    enum Flag: String {
        case seen
        case flagged
        
        var reversed: String { get { return "un\(self.rawValue)"  } }
    }
    
    enum Error: Swift.Error, LocalizedError {
        
        var errorDescription: String? { get {
            switch self {
            case .initFail:
                return "Failed to initialize curl"
            case .existParseFail:
                return "Failed to find * XX EXISTS line"
            case .unreadRequestFail:
                return "Failed to request unread messages"
            case .storeOperationFail:
                return "Failed to perform STORE operation"
            case .loginDenied:
                return "Login denied"
            case .cantFindHost(let host):
                return "Could not find host: \(host)"
            case .queryError(let query):
                return "Query '\(query)' seems invalid"
            case .unexpectedError(let errCode):
                return "Error \(errCode)"
            case .searchFail:
                return "Couldn't find anything"
            }
        } }

        case existParseFail  // ours
        case unreadRequestFail  // ours
        case initFail  // ours
        case searchFail // ours
        case loginDenied
        case storeOperationFail
        case cantFindHost(String)
        case queryError(String)
        case unexpectedError(Int)
    }
    
    /// This is shared across calls, make sure not to multi-thread it
    private static let shared = CurlWrapper()
    
    private init() { }
    
    /// Every time this value is set the old value is preprended to it
    /// Every time this is updated, it is extended with its old value.
    /// Set to nil to reset.
    var fullResponse: String! { didSet {
        if self.fullResponse != nil {
            self.fullResponse = (oldValue ?? "") + self.fullResponse
        }
    } }

    // Curl data callback.
    // buffer points to the data buffer, size and num to its length
    // userdata is a custom pointer used to point to this class,
    // so self can be updated (refs to self are invalid in C functions
    // see https://curl.haxx.se/libcurl/c/CURLOPT_WRITEFUNCTION.html
    private static let writeFunc: curl_func = {
        (bufferPointer, size, num, userdata) -> Int in
        
        let typedPointer = bufferPointer!.assumingMemoryBound(to: UInt8.self)
        let count = size*num
        let buf = UnsafeBufferPointer(start: typedPointer, count: count)
        let data = Data(buffer: buf)
        
        if let string = String(data: data, encoding: .ascii) {
            // resurrect itself from a pointer
            // use unretained because we don't care about memory
            // (we already know self is alive)
            let receivingWrapper = Unmanaged<CurlWrapper>
                .fromOpaque(userdata!)
                .takeUnretainedValue()
            
            receivingWrapper.fullResponse = string
        }
        
        return count
    }
    
    /// Returns the number of messages in the given mailbox and the number of unread
    /// messages in it.
    /// nil if the mailbox doesn't exist
    static func getInfo(serverDetails: ServerDetails, inboxName: String = "INBOX") throws -> (msgCount: Int, unread: [Int])? {
        
        // set this to to express success, otherwise we'll return nil
        var success = false
        
        guard let curl = curl_easy_init()  else { throw Error.initFail }

        defer { curl_easy_cleanup(curl) }
        
        shared.fullResponse = nil
        
        curl_easy_setopt_cstr(curl, CURLOPT_USERNAME, serverDetails.username)
        curl_easy_setopt_cstr(curl, CURLOPT_PASSWORD, serverDetails.password)
        curl_easy_setopt_cstr(curl, CURLOPT_URL, "imaps://\(serverDetails.address)")
        curl_easy_setopt_cstr(curl, CURLOPT_CUSTOMREQUEST, "EXAMINE \(inboxName)")
        curl_easy_setopt_func(curl, CURLOPT_WRITEFUNCTION, CurlWrapper.writeFunc)
        
        // send over an unretained pointer of itself
        // we don't care about memory here, so make sure
        // the lifecycle of this object is taken care of somewhere else
        curl_easy_setopt_ptr(curl, CURLOPT_WRITEDATA, Unmanaged.passUnretained(shared).toOpaque())
        
        var res = curl_easy_perform(curl)

        success = res == CURLE_OK
        
        if res == CURLE_COULDNT_RESOLVE_HOST {
            throw Error.cantFindHost(serverDetails.address)
        } else if res == CURLE_LOGIN_DENIED {
            throw Error.loginDenied
        }
        
        guard success, let response = shared.fullResponse else { return nil }
        
        // expected format * ### EXISTS
        let matches = matchesForRegex(pattern: "\\* (\\d+) EXISTS\(lsep)", inString: response)
        
        guard matches.count == 1 && matches[0].numberOfRanges == 2,
              let totalString = matches[0].extract(response, 1),
              let total = Int(totalString) else {
            throw Error.existParseFail
        }
        
        // search for unread messages (since the given date)
        
        curl_easy_setopt_cstr(curl, CURLOPT_URL, "imaps://\(serverDetails.address)/\(inboxName)")
        curl_easy_setopt_cstr(curl, CURLOPT_CUSTOMREQUEST, "SEARCH \(Flag.seen.reversed) \(serverDetails.dateString)")
        shared.fullResponse = nil
        res = curl_easy_perform(curl)
        
        success = res == CURLE_OK
        
        guard success, let unreadResponse = shared.fullResponse else {
            throw Error.unreadRequestFail
        }
        
        // expected format * SEARCH ## ## ##
        let unreadMatches = matchesForRegex(pattern: "(\\d+)", inString: unreadResponse)
        let unread = unreadMatches.compactMap({$0.extract(unreadResponse, 1)}).compactMap({Int($0)})
        
        return (msgCount: total, unread: unread)
        
    }
    
    /// Returns the UIDs for the messages received within the last
    /// x months.
    /// Optionally, a flag can be specified, which will be used to restrict search.
    static func getUIDs(_ serverDetails: ServerDetails, flag: Flag? = nil, invertFlag: Bool = false, inboxName: String = "INBOX") throws -> [Int] {
        
        // set this to to express success, otherwise we'll return nil
        var success = false
        
        guard let curl = curl_easy_init()  else { throw Error.initFail }
        
        defer { curl_easy_cleanup(curl) }
        
        shared.fullResponse = nil
        
        var searchQuery = "SEARCH \(serverDetails.dateString)"
        if let f = flag {
            if invertFlag {
                searchQuery += " \(f.reversed)" // note the space
            } else {
                searchQuery += " \(f.rawValue)" // note the space
            }
        }
        
        // perform search
        curl_easy_setopt_cstr(curl, CURLOPT_USERNAME, serverDetails.username)
        curl_easy_setopt_cstr(curl, CURLOPT_PASSWORD, serverDetails.password)
        curl_easy_setopt_cstr(curl, CURLOPT_URL, "imaps://\(serverDetails.address)/\(inboxName)")
        curl_easy_setopt_cstr(curl, CURLOPT_CUSTOMREQUEST, searchQuery)
        curl_easy_setopt_func(curl, CURLOPT_WRITEFUNCTION, CurlWrapper.writeFunc)
        
        // send over an unretained pointer of itself
        // we don't care about memory here, so make sure
        // the lifecycle of this object is taken care of somewhere else
        curl_easy_setopt_ptr(curl, CURLOPT_WRITEDATA, Unmanaged.passUnretained(shared).toOpaque())
        
        let res = curl_easy_perform(curl)
        
        success = res == CURLE_OK
        
        if res == CURLE_COULDNT_RESOLVE_HOST {
            throw Error.cantFindHost(serverDetails.address)
        } else if res == CURLE_LOGIN_DENIED {
            throw Error.loginDenied
        } else if res == CURLE_QUOTE_ERROR {
            throw Error.queryError(searchQuery)
        }
        
        guard success, let response = shared.fullResponse else { throw Error.searchFail }
        
        // expected format * SEARCH ## ## ##
        let matches = matchesForRegex(pattern: "(\\d+)", inString: response)
        let found = matches.compactMap({$0.extract(response, 1)}).compactMap({Int($0)})
        
        return found

    }

    /// Set the seen flag according to read status
    static func setFlag(_ flag: Flag, to state: Bool, uid: Int, serverDetails: ServerDetails, inboxName: String = "INBOX") throws {
        
        // set this to to express success, otherwise we'll return nil
        var success = false
        
        guard let curl = curl_easy_init()  else { throw Error.initFail }
        
        defer { curl_easy_cleanup(curl) }
        
        shared.fullResponse = nil
        
        // is + if we want to set flag, - to unset
        let f: String = state ? "+" : "-"
        
        curl_easy_setopt_cstr(curl, CURLOPT_USERNAME, serverDetails.username)
        curl_easy_setopt_cstr(curl, CURLOPT_PASSWORD, serverDetails.password)
        curl_easy_setopt_cstr(curl, CURLOPT_URL, "imaps://\(serverDetails.address)/\(inboxName)")
        curl_easy_setopt_cstr(curl, CURLOPT_CUSTOMREQUEST, "STORE \(uid) \(f)Flags \\\(flag.rawValue)")
        curl_easy_setopt_func(curl, CURLOPT_WRITEFUNCTION, CurlWrapper.writeFunc)
        
        // send over an unretained pointer of itself
        // we don't care about memory here, so make sure
        // the lifecycle of this object is taken care of somewhere else
        curl_easy_setopt_ptr(curl, CURLOPT_WRITEDATA, Unmanaged.passUnretained(shared).toOpaque())
        
        let res = curl_easy_perform(curl)
        
        guard res == CURLE_OK, shared.fullResponse != nil else { throw Error.storeOperationFail }
        
    }


}
