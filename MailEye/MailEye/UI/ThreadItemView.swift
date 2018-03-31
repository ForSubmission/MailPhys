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

class ThreadItemView: NSCollectionViewItem {

    @IBOutlet weak var senderLabel: NSTextField!
    @IBOutlet weak var previewLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var subjectLabel: NSTextField!
    @IBOutlet weak var doneTick: NSTextField!
    @IBOutlet weak var unreadMark: NSTextField!
    @IBOutlet weak var repliedMark: NSTextField!
    @IBOutlet weak var attachmentMark: NSTextField!
    
    var referencedId: String?
    
    let defaultColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    let selectedColor = NSColor.selectedTextBackgroundColor
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
//        self.view.layer!.backgroundColor = CGColor.clear
        NotificationCenter.default.addObserver(self, selector: #selector(messageDone), name: Constants.doneMessageNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(messageRead), name: Constants.readMessageNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(messageReplied), name: Constants.repliedMessageNotification, object: nil)
    }
    
    func updateValues(fromMessage message: Message) {
        setSelected(selected: self.isSelected)
        if let senderName = message.senderName {
            self.senderLabel.stringValue = senderName
        } else {
            self.senderLabel.stringValue = message.sender
        }
        self.subjectLabel.stringValue = message.subject
        self.timeLabel.stringValue = AppSingleton.userDateFormatter.string(from: message.date)
        self.previewLabel.stringValue = message.body.previewVersion
        self.referencedId = message.id
        (self.view as! ReferenceView).correspondingMessageId = message.id
        
        // parent of parent should be MessageViewController
        guard let mbox = (self.collectionView as? ThreadCollectionView)?.mailbox else {
            fatalError("Where's the mailbox?")
        }
        
        DispatchQueue.main.async {
            self.doneTick.isHidden = !HistoryManager.doneMessages.contains(message.id)
            self.unreadMark.isHidden = !mbox.unreadMessages.contains(message.id)
            self.repliedMark.isHidden = !mbox.replies.map({$0.id}).contains(message.id)
            self.attachmentMark.isHidden = !message.containsAttachments
        }
    }
    
    func setSelected(selected: Bool) {
        if selected {
            self.view.layer!.backgroundColor = selectedColor.cgColor
        } else {
            self.view.layer!.backgroundColor = defaultColor.cgColor
        }
    }
    
    // MARK: - Notification callbacks
    
    @objc func messageDone(_ notification: Notification?) {
        guard let uInfo = notification?.userInfo,
              let id = uInfo["messageId"] as? String else {
            return
        }
        if let ourId = self.referencedId, ourId == id {
            DispatchQueue.main.async {
                self.doneTick.isHidden = false
            }
        }
    }
    
    @objc func messageReplied(_ notification: Notification?) {
        guard let uInfo = notification?.userInfo,
            let id = uInfo["messageId"] as? String else {
                return
        }
        if let ourId = self.referencedId, ourId == id, let status = uInfo["status"] as? Bool {
            DispatchQueue.main.async {
                self.repliedMark.isHidden = status
            }
        }
    }
    
    @objc func messageRead(_ notification: Notification?) {
        guard let uInfo = notification?.userInfo,
            let id = uInfo["messageId"] as? String else {
                return
        }
        if let ourId = self.referencedId, ourId == id {
            DispatchQueue.main.async {
                self.unreadMark.isHidden = true
            }
        }
    }
    
}
