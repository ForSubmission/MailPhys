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

protocol MailEyeTesting {
    
}

extension MailEyeTesting {
        
    func verify(mailbox: Mailbox, againstGroundTruth groundTruth: MboxGroundTruth) {
        // verify substrings that should be found in body
        XCTContext.runActivity(named: "Find expected strings") {
            activity in
            
            groundTruth.shouldContain.forEach() {
                (i, value) in
                
                value.forEach() {
                    expectedString in
                    
                    let body = mailbox.allMessages[i]?.body
                    verifyExpected(string: expectedString, inContents: body, mustBePresent: true, activity: activity)
                }
                
            }
        }
        
        // verify substrings that should be found in subjects
        XCTContext.runActivity(named: "Find expected strings in subjects") {
            activity in
            
            groundTruth.subjectShouldContain.forEach() {
                (i, value) in
                
                value.forEach() {
                    expectedString in
                    
                    let subject = mailbox.allMessages[i]?.subject
                    verifyExpected(string: expectedString, inContents: subject, mustBePresent: true, activity: activity)
                }
            }
        }
        
        // test for substrings that should not be found in  body
        XCTContext.runActivity(named: "Reject unexpected strings") {
            activity in
            
            groundTruth.shouldNotContain.forEach() {
                (i, value) in
                
                value.forEach() {
                    unexpectedString in
                    
                    let body = mailbox.allMessages[i]?.body
                    verifyExpected(string: unexpectedString, inContents: body, mustBePresent: false, activity: activity)
                }
                
            }
        }
        
        // verify substrings that should not be found in subjects
        XCTContext.runActivity(named: "Find unexpected strings in subjects") {
            activity in
            
            groundTruth.subjectShouldNotContain.forEach() {
                (i, value) in
                
                value.forEach() {
                    expectedString in
                    
                    let subject = mailbox.allMessages[i]?.subject
                    verifyExpected(string: expectedString, inContents: subject, mustBePresent: false, activity: activity)
                }
            }
        }
        
        // verify name matches
        XCTContext.runActivity(named: "Sender name checking") {
            activity in
            
            groundTruth.nameMustBe.forEach() {
                (i, expectedName) in
                
                let senderName = mailbox.allMessages[i]?.senderName
                XCTAssertEqual(expectedName, senderName)
            }
        }

    }
    
    func verifyExpected(string: String, inContents: String?, mustBePresent: Bool, activity: XCTActivity) {
        guard let inContents = inContents else {
            XCTFail("Found nil contents")
            return
        }
        
        let contentsAttachment = XCTAttachment(string: inContents)
        contentsAttachment.name = "Tested contents"
        let stringAttachment = XCTAttachment(string: string)
        let appendage: String = mustBePresent ? "(expected)" : "(not expected)"
        stringAttachment.name = "Tested string \(appendage)"
        activity.add(contentsAttachment)
        activity.add(stringAttachment)
        XCTAssert(inContents.contains(string) == mustBePresent, "String verification \(appendage).")
    }
    
}
