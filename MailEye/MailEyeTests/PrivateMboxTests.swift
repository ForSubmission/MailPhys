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

class PrivateMboxTests: XCTestCase, MailEyeTesting {
    
    override func setUp() {
        HistoryManager.demoing = true
    }
    
    /// Sequentially updated by verifyMbox
    var mbox: Mbox!
    
    func testMboxTiny() {
        verifyMbox(PrivateTestData.tinyMbox)
    }
    
    func testMboxSmall() {
        verifyMbox(PrivateTestData.smallMbox)
    }
    
    func testMboxMedium() {
        verifyMbox(PrivateTestData.mediumMbox)
    }
    
    func testMboxOne() {
        verifyMbox(PrivateTestData.mboxOne)
    }

    func testGoogleMbox() {
        verifyMbox(PrivateTestData.googleMbox)
    }


    func verifyMbox(_ groundTruth: MboxGroundTruth) {
        let loadExpectation = expectation(description: "Mbox \(groundTruth.name) load")
        
        guard let mbox = Mbox(inUrl: groundTruth.url) else {
            XCTFail("Failed to load mbox: \(groundTruth.url)")
            return
        }
        
        self.mbox = mbox
        self.mbox.loadMbox() {
            loadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 60.0)
        
        XCTContext.runActivity(named: "Test mbox \(name)") {
            activity in
            
            verify(mailbox: self.mbox, againstGroundTruth: groundTruth)
        }
    }

}


