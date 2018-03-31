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

extension Mailbox {
    
    /// Asynchronously loads messages, updating progress.
    /// completionHandler is called when done.
    /// Should be called when the mailbox is ready to work and
    /// all receiving controllers are ready.
    func loadMbox(loadingController: LoadingViewController? = nil, partialCompletionHandler: ((Int) -> Void)? = nil, completionHandler: (() -> ())? = nil) {
        
        let queue = DispatchQueue(label: "mailbox.loadQueue", qos: .userInitiated)
        queue.asyncAfter(deadline: .now() + 1) {
            [unowned self] in
            
            let msgCount = self.allMessages.count
            
            DispatchQueue.main.async {
                loadingController?.progress = self.loadingProgress
                self.loadingProgress.totalUnitCount = Int64(msgCount)
            }
            
            // main loop for loading messages.
            // it can be cancelled by the loadingprogress
            for rowNo in 0 ..< self.allMessages.count {
                
                guard !self.loadingProgress.isCancelled else {
                    break
                }
                
                do {
                    
                    let mess = try self.fetchMessage(atIndex: rowNo)
                    
                    DispatchQueue.main.async {
                        [unowned self] in
                        self.allMessages[rowNo] = mess
                        partialCompletionHandler?(rowNo)
                    }
                    
                    self.messageIndex[mess.id] = rowNo
                    
                } catch let error as Message.Error {
                    
                    do {
                        if let fullContents = try self.fetchFullContents(atIndex: rowNo) {
                            DispatchQueue.main.async {
                                self.allMessages[rowNo] = Message(placeholderForError: error, fullContents: fullContents)
                                self.erroneousMessages.append(rowNo)
                                partialCompletionHandler?(rowNo)
                            }
                        }
                        
                        if #available(OSX 10.12, *) {
                            os_log("Error while parsing messages: %@", type: .error, error.localizedDescription)
                        }
                        loadingController?.displayError(error, rowNo)
                    } catch {
                        loadingController?.displayError(error, rowNo)
                    }
                    
                } catch {
                    if #available(OSX 10.12, *) {
                        os_log("Unexpected error: %@", type: .error, error.localizedDescription)
                    }
                    loadingController?.displayError(error, rowNo)
                }
                
                DispatchQueue.main.async {
                    [weak self] in
                    
                    guard let strongSelf = self else {
                        return
                    }
                    
                    strongSelf.loadingProgress.completedUnitCount = strongSelf.loadingProgress.completedUnitCount + 1
                    strongSelf.loadingProgress.localizedDescription = "\(strongSelf.loadingProgress.completedUnitCount) / \(msgCount)"
                }
            }
            
            DispatchQueue.global(qos: .userInteractive).async {
                completionHandler?()
            }
            
        }
    }
    
    
    /// Returns the message for a given id using the pre-built index
    func getMessage(forId id: String) -> Message? {
        guard let i = messageIndex[id] else {
            return nil
        }
        
        return allMessages[i]
    }
    
    /// Sorts the messages in descending order of date.
    /// Number 0 should be the last message received.
    func sortMessages() throws {
        try self.allMessages.sort(by: {_a, _b in
            guard let a = _a, let b = _b else {
                throw Constants.Error.sortFail
            }
            
            return a.date.compare(b.date) == .orderedDescending
            
        })
        
        messageIndex = [:]
        erroneousMessages = []
        for i in 0 ..< allMessages.count {
            guard let m = allMessages[i] else {
                continue
            }
            
            if m.id != Constants.failedMessageId {
                messageIndex[m.id] = i
            } else {
                erroneousMessages.append(i)
            }
        }
    }
        
    /// Returns the direct thread (reply chain) for the given message,
    /// sorted by ascending dates.
    func getThread(forMessage message: Message) ->  [Message] {
        
        var threadIds = Set<String>()
        
        // get all messages replied by this message
        // for all messages found, add everything they replied to until
        // there are no more messages to scan
        // remember to always skip current message id and everything that
        // was already scanned
        var toScan = Set(message.repliesTo ?? [])
        let toSkip = Set([message.id])
        while toScan.count > 0 {
            toScan.subtract(toSkip)
            toScan.subtract(threadIds)
            guard let next = toScan.popFirst() else {
                break
            }
            threadIds.insert(next)
            guard let nextMessage = getMessage(forId: next) else {
                if #available(OSX 10.12, *) {
                    os_log("Couldn't find any message for id: %@", type: .debug, next)
                }
                continue
            }
            if let nextBunch = nextMessage.repliesTo {
                toScan.formUnion(nextBunch)
            }
        }
        
        if let references = message.references {
            threadIds.formUnion(references)
        }
        
        // flatten and sort result by date
        return threadIds.compactMap() { getMessage(forId: $0) }
            .sorted()
                { $0.date.compare($1.date) == .orderedAscending }
        
    }
    
}
