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

/// This class is used as a convenience to snd data to dime
class DiMePusher {
        
    /// Send the given data to dime
    /// - parameter callback: When done calls the callback where the first parameter is a boolean (true if successful)
    static func sendToDiMe<Data>(_ dimeData: Data, endpoint: DiMeEndpoint, callback: ((Bool) -> Void)? = nil) where Data: DiMeData {
        guard DiMeSession.dimeAvailable else {
            callback?(false)
            return
        }
       
        do {
            // attempt to translate json
            let data = try DiMeSession.jsonEncoder.encode(dimeData)
            
            // assume json conversion was a success, hence send to dime
            let server_url = DiMeSession.dimeUrl
            DiMeSession.push(urlString: server_url + "/data/\(endpoint.rawValue)", data: data) {
                data, _ in
                
                guard let data = data else {
                    return
                }
                
                if let dimeErrorResponse = try? DiMeSession.jsonDecoder.decode(DiMeResponse.self, from: data) {
                    // if we got here this was an error
                    
                    if let error = dimeErrorResponse.error,
                       #available(OSX 10.12, *) {
                        os_log("DiMe reply to submission contains error: %@", log: DiMeLog, type: .error, error)
                    }

                    if let message = dimeErrorResponse.message,
                       #available(OSX 10.12, *) {
                        os_log("DiMe's error message: %@", log: DiMeLog, type: .error, message)
                    }

                    callback?(false)
                } else {
                    callback?(true)
                }
                
            }
        } catch {
            if #available(OSX 10.12, *) {
                os_log("Error while serializing json: %@", log: DiMeLog, type: .error, error.localizedDescription)
            }
            callback?(false)
        }
            
    }

}
