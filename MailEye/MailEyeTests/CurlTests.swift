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

import XCTest
@testable import MailEye

class CurlTests: XCTestCase, MailEyeTesting {
    
    let serverDetails = Constants.publicServerDetails
    
    func testCurl() {
        
        /// nil messages in blabla inbox
        let numZero = try! CurlWrapper.getInfo(serverDetails: serverDetails, inboxName: "blabla")
        XCTAssert(numZero == nil, "blabla should not exist")
        
        /// > 0 messages in INBOX inbox
        if let numMore = try! CurlWrapper.getInfo(serverDetails: serverDetails) {
            XCTAssert(numMore.msgCount > 0, "blabla should contain 0 messages")
        } else {
            XCTFail("Couldn't get n of messages")
        }
        
        XCTContext.runActivity(named: "First message parsing") {
            activity in
            
            do {
                
                /// message 1 should be somewhat long
                guard let firstMess = try CurlMessage(serverDetails: serverDetails, uid: 1) else {
                    XCTFail("Where's the first message?")
                    return
                }
                
                XCTAssert(firstMess.fullContents.count > 100, "First message should be somewhat long")
                
                let att = XCTAttachment(string: firstMess.fullContents)
                att.name = "First message"
                activity.add(att)
                
                let mess = try Message(fromCurlMessage: firstMess)
                
                XCTAssert(mess.senderName! == "iCloud", "first message is from iCloud")
                
            } catch {
                XCTFail("Message creation exception: \(error.localizedDescription)")
            }
            
        }
        
        XCTContext.runActivity(named: "Set 5 to unread, fetch it and set it back and back") {
            activity in
            
            do {
                try CurlWrapper.setFlag(.seen, to: false, uid: 5, serverDetails: serverDetails)
                
                guard let infoBefore = try CurlWrapper.getInfo(serverDetails: serverDetails) else {
                    XCTFail("Can't get info before")
                    return
                }
                
                XCTAssert(infoBefore.unread.contains(5), "5 should be unread")
                
                /// message 5 should be somewhat long
                guard let messFive = try CurlMessage(serverDetails: serverDetails, uid: 5) else {
                    XCTFail("Couldn't get message 5")
                    return
                }
                
                XCTAssert(messFive.fullContents.count > 100, "Fifth message should be somewhat long")
                
                guard let infoAfter = try CurlWrapper.getInfo(serverDetails: serverDetails) else {
                    XCTFail("Can't get info after")
                    return
                }
                
                XCTAssertFalse(infoAfter.unread.contains(5), "5 should be read now")
                
            } catch {
                XCTFail("Exception: \(error.localizedDescription)")
            }
            
        }
        
    }

}

