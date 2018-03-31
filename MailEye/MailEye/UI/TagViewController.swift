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
import Cocoa
import os.log

class TagViewController: NSViewController {
    
    // MARK: - Response fields
    
    var priority: Int = 0 { didSet {
        checkStatus()
    } }
    var pleasure: Int = 0 { didSet {
        checkStatus()
    } }
    var workload: Int = 0 { didSet {
        checkStatus()
    } }
    var spam: Bool = false { didSet {
        checkStatus()
        if oldValue != spam {
            setSpam()
        }
    } }
    
    var corrupted: Bool = false { didSet {
        checkStatus()
    } }
    
    var endTime: Date = Date()
    var eager: Bool = false
    
    // MARK: - Other fields
    
    @IBOutlet weak var spamButton: NSButton!
    @IBOutlet weak var eagerButton: NSButton!
    
    weak var mailbox: Mailbox?
    var messageId: String?
    @IBOutlet weak var doneButton: NSButton!
    
    @IBOutlet weak var priorityBox: NSBox!
    @IBOutlet weak var pleasureBox: NSBox!
    @IBOutlet weak var workloadBox: NSBox!
    
    override func viewDidAppear() {
        HistoryManager.paused = true
        endTime = Date()
        guard self.messageId != nil else {
            if #available(OSX 10.12, *) {
                os_log("No message id for tagging", type: .error)
            }
            DispatchQueue.main.async {
                [weak self] in
                self?.view.window?.close()
            }
            return
        }
    }
    
    override func viewWillDisappear() {
        HistoryManager.paused = false
    }
    
    // MARK: - Private functions
    
    /// If we can enable done or not
    private func checkStatus() {
        let enableButton = corrupted || spam || priority != 0 && pleasure != 0 && workload != 0
        if enableButton != self.doneButton.isEnabled {
            DispatchQueue.main.async {
                [weak self] in
                self?.doneButton.isEnabled = enableButton
            }
        }
    }
    
    /// Sets all buttons to disabled if this is spam
    private func setSpam() {
        let enabled = !spam
        DispatchQueue.main.async {
            [weak self] in
            self?.eagerButton.isEnabled = enabled
            self?.priorityBox.subviews[0].subviews.forEach() {
                if let but = $0 as? NSButton {
                    but.isEnabled = enabled
                }
            }
            self?.pleasureBox.subviews[0].subviews.forEach() {
                if let but = $0 as? NSButton {
                    but.isEnabled = enabled
                }
            }
            self?.workloadBox.subviews[0].subviews.forEach() {
                if let but = $0 as? NSButton {
                    but.isEnabled = enabled
                }
            }
        }
    }
    
    // MARK: - Actions
    
    /// Tags: 1 - low, 2 - medium low, 3 - medium high, 4 - high
    
    @IBAction func priorityPress(_ sender: NSButton) {
        priority = sender.tag
    }
    
    @IBAction func pleasurePress(_ sender: NSButton) {
        pleasure = sender.tag
    }
    
    @IBAction func workloadPress(_ sender: NSButton) {
        workload = sender.tag
    }
    
    @IBAction func eagerPress(_ sender: NSButton) {
        eager = sender.state == .on
        DispatchQueue.main.async {
            [unowned self] in
            self.spamButton.isEnabled = sender.state == .off
        }
    }

    @IBAction func corruptedPress(_ sender: NSButton) {
        corrupted = sender.state == .on
    }
    
    @IBAction func spamPressed(_ sender: NSButton) {
        spam = sender.state == .on
        DispatchQueue.main.async {
            [unowned self] in
            self.eagerButton.isEnabled = sender.state == .off
        }
    }
    
    @IBAction func cancelPressed(_ sender: NSButton) {
        HistoryManager.currentVisitId = self.messageId
        HistoryManager.resumeBehavioural()
        DispatchQueue.main.async {
            [weak self] in
            self?.dismiss(nil)
        }
    }
    
    @IBAction func donePressed(_ sender: NSButton) {
        
        defer {
            DispatchQueue.main.async {
                [weak self] in
                self?.dismiss(nil)
            }
        }
        
        guard let messageId = self.messageId else {
            return
        }
        
        NotificationCenter.default.post(name: Constants.doneMessageNotification, object: self, userInfo: ["messageId": messageId])
        HistoryManager.doneMessages.insert(messageId)
        
        if corrupted {
            HistoryManager.corruptedMessages.insert(messageId)
            // make template reply if message was not replied by user
            if let mailbox = mailbox, !mailbox.replies.map({$0.id}).contains(messageId) {
                mailbox.addReply(id: messageId, reply: "(was corrupted)")
            }
        }
        
        HistoryManager.currentWork?.setTags(priority: self.priority, pleasure: self.pleasure, workload: self.workload, spam: self.spam, eager: self.eager, corrupted: self.corrupted)
        HistoryManager.currentWork?.done(endTime)
        HistoryManager.currentWork?.fetchBehavioural()
        
        if let cw = HistoryManager.currentWork {
            AppSingleton.writeToDownloads(dimeData: cw)
        }
        
        HistoryManager.currentWork = nil
        HistoryManager.currentWorkMessageRow = nil
        HistoryManager.currentWorkMessageId = nil
    }
}
