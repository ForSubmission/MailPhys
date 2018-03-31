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

class ChunkTests: XCTestCase {
    
    override func setUp() {
        HistoryManager.demoing = true
    }
    
    struct ChunkGroundTruth {
        /// Every key refers to an email in the mbox, and the associated array contains strings
        /// that SHOULD be present in the body of the given email
        let shouldContain: [Int: [String]]
        
        /// Every key refers to an email in the mbox, and the associated array contains strings
        /// that SHOULD NOT be present in the body of the given email
        let shouldNotContain: [Int: [String]]
    }
    
    var url: URL { get {
        return Bundle(for: PrivateTestData.self).url(forResource: "chunks", withExtension: "")!
    }}

    func testChunks() {
        
        let chunksTruth = ChunkGroundTruth(
            shouldContain: [
                1: ["Hällströmin"],
                2: ["wz3U2HoAAAAJ"],
                3: ["لا تتحمل جامعة"],
                4: ["Final Call For Workshop Proposals"]
            ],
            shouldNotContain: [
                3: ["???"]
            ]
        )

        let all = try! String(contentsOf: url)
        
        let chunks = all.components(separatedBy: "\n---\n")
        
        XCTContext.runActivity(named: "Chunk testing") {
            activity in
            
            // skip first chunk (is a "readme")
            for i in 1..<chunks.count {
                
                // the header is everything up until a double newline
                guard let sepRange = chunks[i].range(of: "\n\n") else {
                    XCTFail("chunks file not formatted properly")
                    break
                }
                
                let header = String(chunks[i][...sepRange.lowerBound])
                
                let body = String(chunks[i][sepRange.upperBound...])
                
                let chunk = try! MessageChunk(fromHeader: header, possibleBody: body, id: "\(i)")
                
                XCTAssert(chunk.body != nil, "Chunk must contain something")
                
                verifyChunk(body: chunk.body ?? "", i: i, groundTruth: chunksTruth, activity: activity)
            }

        }
        
    }
    
    private func verifyChunk(body: String, i: Int, groundTruth: ChunkGroundTruth, activity: XCTActivity) {
        
        let attachment = XCTAttachment(string: body)
        attachment.name = "Decoded chunk \(i)"
        activity.add(attachment)
        
        if let mustContain = groundTruth.shouldContain[i] {
            for item in mustContain {
                XCTAssert(body.contains(item), "Chunk \(i) should contain \(item)")
            }
        }
        if let mustNotContain = groundTruth.shouldNotContain[i] {
            for item in mustNotContain {
                XCTAssertFalse(body.contains(item), "Chunk \(i) should NOT contain \(item)")
            }
        }
    }

}
