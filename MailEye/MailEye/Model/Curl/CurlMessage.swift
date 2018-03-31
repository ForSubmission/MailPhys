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

class CurlMessage {
    
    /// True if we were asked to reset read (the message was unseen)
    let isRead: Bool
    
    /// Every time this value is set the old value is preprended to it
    /// Every time this is updated, it is extended with its old value.
    var fullContents: String! { didSet {
        if self.fullContents != nil {
            self.fullContents = (oldValue ?? "") + self.fullContents
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
        
        let encoding = NSString.stringEncoding(for: data, encodingOptions: nil, convertedString: nil, usedLossyConversion: nil)
        
        if let string = String(data: data, encoding: String.Encoding(rawValue: encoding)) {
            // resurrect itself from a pointer
            // use unretained because we don't care about memory
            // (we already know self is alive)
            let receivingMessage = Unmanaged<CurlMessage>
                .fromOpaque(userdata!)
                .takeUnretainedValue()
            
            receivingMessage.fullContents = string
        }
        
        return count
    }
    
    /// Fetch the specified message using curl, using the
    /// server, username and password specified somewhere else
    /// (e.g. Constants singleton class)
    /// Note: UIDs start from 1, not 0
    /// If reset read is set to true, message will be set to unread immediately afterwards
    init?(serverDetails: ServerDetails, inboxName: String = "INBOX", uid: Int, resetRead: Bool = false) throws {
    
        self.isRead = !resetRead
        
        // set this to to express success, otherwise we'll return nil
        var success = false
    
        guard let curl = curl_easy_init()  else { return nil }
        
        curl_easy_setopt_cstr(curl, CURLOPT_USERNAME, serverDetails.username)
        curl_easy_setopt_cstr(curl, CURLOPT_PASSWORD, serverDetails.password)
        // note that message UID starts from 1, not 0
        curl_easy_setopt_cstr(curl, CURLOPT_URL, "imaps://\(serverDetails.address)/\(inboxName);UID=\(uid)")
        curl_easy_setopt_func(curl, CURLOPT_WRITEFUNCTION, CurlMessage.writeFunc)
        
        // send over an unretained pointer of itself
        // we don't care about memory here, so make sure
        // the lifecycle of this object is taken care of somewhere else
        curl_easy_setopt_ptr(curl, CURLOPT_WRITEDATA, Unmanaged.passUnretained(self).toOpaque())
        
        let res = curl_easy_perform(curl)
        
        if res == CURLE_OK {
            success = true
        }
        
        curl_easy_cleanup(curl)
        
        if !success { return nil }
        
        if resetRead {
            try CurlWrapper.setFlag(.seen, to: false, uid: uid, serverDetails: serverDetails, inboxName: inboxName)
        }
            
    }

}
