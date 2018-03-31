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

import Cocoa
import os.log

/// The main view controller managin a table (thread list) and the currently displayed message / thread
class MailboxController: NSSplitViewController, NSWindowDelegate {
    
    /// Sets to true if the window is moving, then false again when done
    var moveLock = false
    
    /// Queue on which tempWorkTimer (which checks tempWorkMessageIndex) is set
    private static let timerQueue = DispatchQueue(label: "anon.forsubmission.mailboxcontroller.timerqueue", qos: .userInitiated)
    
    /// Timer that starts once the user selects a new message.
    /// The timer is nullified once the user selects another message before the Constants.workTime threshold or
    /// when the timer triggers.
    private var tempWorkTimer: Timer?
    
    /// Points to the message index that the user last visited. -1 if invalid.
    /// It is only set to something different than -1 if the user is not working on anything.
    /// Once Constants.workTime passes, we assume the user is working on this message (if this value didn't change in the meantime).
    var tempWorkMessageIndex = -1 { didSet {
        guard oldValue != tempWorkMessageIndex else {
            return
        }
        
        MailboxController.timerQueue.sync {
            // invalidate timer
            if tempWorkTimer != nil {
                tempWorkTimer?.invalidate()
                tempWorkTimer = nil
            }
        
            // create a new timer if index is valid
            if tempWorkMessageIndex != -1 {
                let timer = Timer(timeInterval: Constants.workTime, target: self, selector: #selector(tempWorkTimerTriggered), userInfo: nil, repeats: false)
                RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
                tempWorkTimer = timer
            }
        
        }
    } }
    
    weak var allController: AllMessagesController!
    weak var messageController: MessageController!
    
    let drawDebugCircle: Bool = {
        return UserDefaults.standard.object(forKey: EyeConstants.prefDrawDebugCircle) as! Bool
    }()

    var readyToReceive = false
    
    /// Sets to true if we are trying to close this
    var closeToken = false
    
    // MARK: - Tracking vars
    
    /// When the user started reading (stoppedReading date - this date = reading time).
    /// Should be set to nil when the user stops reading, or on startup.
    /// Setting this value to a new value automatically increases the totalReadingTime
    /// (takes into consideration minimum reading values constants)
    var lastStartedReading: Date? {
        didSet {
            // increase total reading time constant if reading time was below minimum.
            // if reading time was above maximum, increase by maximum
            if let rdate = oldValue {
                let rTime = Date().timeIntervalSince(rdate)
                if rTime > EyeConstants.minReadTime {
                    if rTime < EyeConstants.maxReadTime {
                        totalReadingTime += rTime
                    } else {
                        totalReadingTime += EyeConstants.maxReadTime
                    }
                }
            }
        }
    }
    
    /// Total reading time spent on this window.
    var totalReadingTime: TimeInterval = 0
        
    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.readyToReceive = false
        allController = self.childViewControllers[0] as? AllMessagesController
        messageController = self.childViewControllers[1] as? MessageController
        
        // Setup observers for scrolling, etc
        setObservers()
        
        // reset toolbar
        self.invalidateRestorableState()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if let win = self.view.window, win.delegate !== self {
            win.delegate = self
        }
        entered(nil)
    }
    
    override var representedObject: Any? {
        didSet {
            guard representedObject is Mailbox else {
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                [weak self] in
                
                self?.allController.allMessagesTable.reloadData()
                self?.readyToReceive = true
            }
        
        } }
    
    @IBAction func sortMessages(_ sender: AnyObject?) {
        guard let mailbox = self.allController.mailbox else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try mailbox.sortMessages()
                
                DispatchQueue.main.async {
                    [weak self] in
                    self?.allController?.allMessagesTable?.reloadData()
                }
            } catch {
                DispatchQueue.main.async {
                    AppSingleton.alertUser(error.localizedDescription)
                }
            }
        }
    }
    
    /// Loads one message
    func partialCompletionHandler(_ row: Int) {
        let mailbox = representedObject as! Mailbox
        guard readyToReceive else {
            return
        }
        let rv = allController.allMessagesTable.rowView(atRow: row, makeIfNecessary: false)
        if let cell = rv?.subviews[0] as? MailboxCell {
            cell.updateValues(fromMessage: mailbox.allMessages[row]!, mailbox: mailbox)
        }
    }
    
    // MARK: - Start work
    
    @objc func tempWorkTimerTriggered(timer: Timer) {
        MailboxController.timerQueue.sync {
            self.tempWorkTimer = nil
        }
        
        if tempWorkMessageIndex > -1 {
            // start working on this message
            guard let msgId = messageController.messageId,
                let msgIndex = allController.mailbox.messageIndex[msgId],
                msgIndex == tempWorkMessageIndex,
                let message = allController.mailbox.allMessages[msgIndex] else {
                    return
            }
            
            DispatchQueue.main.async {
                [unowned self] in
                self.messageController.workingOnLabel.stringValue = message.subject
            }
            
            HistoryManager.resetBehavioural()
            HistoryManager.currentWorkMessageId = msgId
            HistoryManager.currentWorkMessageRow = msgIndex
            
            // validate items on main queue so that "Done" is enabled if needed,
            // since currentWork just changed
            DispatchQueue.main.async {
                self.messageController.view.window?.toolbar?.validateVisibleItems()
            }
            
            let bodySize = messageController.bodyView.bounds.size
            
            HistoryManager.currentWork = AugmentedMessage(fromMessage: message, bodySize: bodySize,
                                                          preVisits: HistoryManager.preVisits.removeValue(forKey: msgId),
                                                          preGazes: HistoryManager.preGazes.removeValue(forKey: msgId),
                                                          preKeywords: HistoryManager.preKeywords.removeValue(forKey: msgId),
                                                          preSelections: HistoryManager.preSelections.removeValue(forKey: msgId))
            
            HistoryManager.trackRawGaze = true

        }
    }
    
    // MARK: - Unload
    
    func unload() {
        guard !closeToken else {
            return
        }
        closeToken = true
        
        HistoryManager.completeAllAugmentedMessages()
    }
    
    // MARK: - Overrides
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.tag == 556712 {
            return allController?.mailbox?.loadingProgress.completedUnitCount ?? -1
                >= allController?.mailbox?.loadingProgress.totalUnitCount ?? 0
        } else {
            return super.validateMenuItem(menuItem)
        }
    }
    
    override func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier.rawValue {
        case "msgActionReply":
            return messageController.messageId ?? Constants.failedMessageId != Constants.failedMessageId
        case "msgActionDone":
            guard let msgId = messageController.messageId,
                  let curMsgId = HistoryManager.currentWorkMessageId else {
                return false
            }
            return msgId == curMsgId
        case "msgActionStart":
            guard let msgId = messageController.messageId, HistoryManager.currentWorkMessageId == nil else {
                return false
            }
            return msgId != Constants.failedMessageId &&
                !HistoryManager.doneMessages.contains(msgId)
        case "msgActionBack":
            return HistoryManager.currentWorkMessageId != nil && HistoryManager.currentWorkMessageId != messageController.messageId
        default:
            return super.validateToolbarItem(item)
        }
    }
    
    // MARK: - Window Delegate
    
    @objc func windowShouldClose(_ sender: NSWindow) -> Bool {
        if let currentWork = HistoryManager.currentWorkMessageId, let win = self.view.window {
            let alert = NSAlert()
            alert.messageText = "Please complete the current message (by clicking on ‘Done’) before closing this window"
            if self.messageController.messageId != currentWork {
                alert.informativeText = "Use ‘Back’ to go back to the message you are working on"
            }
            alert.alertStyle = .warning
            alert.beginSheetModal(for: win)
            return false
        } else {
            return true
        }
    }
    
    // MARK: - Actions
    
    @IBAction func msgActionDone(_ sender: AnyObject?) {
        DispatchQueue.main.async {
            [unowned self] in
            self.messageController.workingOnLabel.stringValue = ""
        }
        
        HistoryManager.trackRawGaze = false

        HistoryManager.currentVisitId = nil
        self.exited(nil)
        HistoryManager.pauseBehavioural()
        messageController.performSegue(withIdentifier: .init("messageDone"), sender: self)
    }
    
    @IBAction func msgActionReply(_ sender: AnyObject?) {
        messageController.performSegue(withIdentifier: .init("composeReply"), sender: self)
    }
    
    @IBAction func msgActionBack(_ sender: AnyObject?) {
        guard let msgId = HistoryManager.currentWorkMessageId else {
            return
        }
        
        let uInfo: [String: Any] = ["messageId": msgId, "tableSelect": true]
        if let row = HistoryManager.currentWorkMessageRow {
            DispatchQueue.main.async {
                [weak self] in
                let ip = IndexSet(integer: row)
                self?.allController.allMessagesTable.selectRowIndexes(ip, byExtendingSelection: false)
            }
        }
        NotificationCenter.default.post(name: Constants.selectMessageNotification, object: self, userInfo: uInfo)
    }

}
