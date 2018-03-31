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

/// Shows all messages (in the future, threads) in the mbox
class AllMessagesController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    /// Becomes true once we add the window close notification observer
    var windowNotificationAdded: Bool = false
    
    var currentError = -1 { didSet {
        DispatchQueue.main.async {
            [unowned self] in
            self.allMessagesTable.selectRowIndexes(IndexSet.init(integer: self.currentError), byExtendingSelection: false)
            self.allMessagesTable.scrollRowToVisible(self.currentError)
        }
    }}
    
    weak var mailbox: Mailbox! { get {
        return (parent as! MailboxController).representedObject as? Mailbox
    } }
    
    weak var messageController: MessageController? { get {
        return (parent as! MailboxController).messageController
    } }
    
    @IBOutlet weak var allMessagesTable: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allMessagesTable.dataSource = self
        allMessagesTable.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(messageSelected(_:)), name: Constants.selectMessageNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(messageDone), name: Constants.doneMessageNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(messageRead), name: Constants.readMessageNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(messageReplied), name: Constants.repliedMessageNotification, object: nil)

    }
    
    override func viewDidAppear() {
        if !windowNotificationAdded {
            self.windowNotificationAdded = true
            NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose), name: NSWindow.willCloseNotification, object: self.view.window!)
        }
    }
    
    // MARK: - Notification callbacks
    
    @objc func windowWillClose(_ notification: Notification) {
        
        // skip if we are demoing
        guard !HistoryManager.demoing else { return }
        
        do {
            try mailbox.saveAllReplies()
        } catch {
            AppSingleton.alertUser("Could not save all replies")
        }
    }
    
    /// A message was selected somewhere else (e.g. from thread), we capture this here
    @objc func messageSelected(_ notification: Notification) {
        guard let id = notification.userInfo?["messageId"] as? String else {
            return
        }
        
        guard let i = mailbox?.messageIndex[id] else {
            return
        }
        
        // if this notification tells us to behave as a normal message was selected,
        // do so
        if notification.userInfo?["tableSelect"] as? Bool ?? false {
            messageController?.messageSelected(i, refreshThread: true)
        } else {
            messageController?.messageSelected(i, refreshThread: false)
        }
    }
    
    @objc func messageDone(notification: Notification?) {
        guard let uinfo = notification?.userInfo,
            let id = uinfo["messageId"] as? String,
            let row = mailbox?.messageIndex[id] else {
                return
        }
        
        let rv = allMessagesTable.rowView(atRow: row, makeIfNecessary: false)
        if let cell = rv?.subviews[0] as? MailboxCell {
            DispatchQueue.main.async {
                if cell.messageId ?? "" == id {
                    cell.doneTick.isHidden = false
                }
            }
        }
    }
    
    @objc func messageRead(notification: Notification?) {
        guard let uinfo = notification?.userInfo,
            let id = uinfo["messageId"] as? String,
            let row = mailbox?.messageIndex[id] else {
                return
        }
        
        let rv = allMessagesTable.rowView(atRow: row, makeIfNecessary: false)
        if let cell = rv?.subviews[0] as? MailboxCell {
            DispatchQueue.main.async {
                if cell.messageId ?? "" == id {
                    cell.unreadMark.isHidden = true
                }
            }
        }
    }
    
    @objc func messageReplied(notification: Notification?) {
        guard let uinfo = notification?.userInfo,
            let id = uinfo["messageId"] as? String,
            let status = uinfo["status"] as? Bool,
            let row = mailbox?.messageIndex[id] else {
                return
        }
        
        let rv = allMessagesTable.rowView(atRow: row, makeIfNecessary: false)
        if let cell = rv?.subviews[0] as? MailboxCell {
            DispatchQueue.main.async {
                if cell.messageId ?? "" == id {
                    cell.repliedMark.isHidden = !status
                }
            }
        }
    }
    
    // MARK: - Menus
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.tag == 366246 {
            return mailbox.erroneousMessages.count > 0
        } else {
            return super.validateMenuItem(menuItem)
        }
    }
    
    @IBAction func nextError(_ sender: AnyObject) {
        if mailbox.erroneousMessages.count > 0 {
            if let bigger = mailbox.erroneousMessages.index(where: {$0 > self.currentError}) {
                self.currentError = mailbox.erroneousMessages[bigger]
            } else {
                self.currentError = mailbox.erroneousMessages[0]
            }
        }
    }
    
    // MARK: - Table view delegate and data source
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return !(mailbox?.allMessages[row] == nil)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return mailbox?.allMessages.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let mailboxCell = allMessagesTable.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MailboxCell"), owner: self) as! MailboxCell
        
        guard let mailbox = self.mailbox else {
            return nil
        }
        
        let possibleMessage = mailbox.allMessages[row]
        
        DispatchQueue.main.async {
            mailboxCell.updateValues(fromMessage: possibleMessage, mailbox: mailbox)
        }
        
        return mailboxCell
    }
    
    /// Sending action because we always want to refresh in case of click
    @IBAction func tableClick(_ sender: Any) {
        messageController?.messageSelected(allMessagesTable.selectedRow)
        
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        messageController?.messageSelected(allMessagesTable.selectedRow)
    }
    
}
