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

class MailboxCell: NSTableCellView, MessageReferenceView {
    
    var messageId: String?
    var correspondingMessageId: String? { get {
        return messageId
    }}
    
    @IBOutlet weak var senderLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var subjectLabel: NSTextField!
    @IBOutlet weak var previewLabel: NSTextField!
    @IBOutlet weak var doneTick: NSTextField!
    @IBOutlet weak var unreadMark: NSTextField!
    @IBOutlet weak var repliedMark: NSTextField!
    @IBOutlet weak var attachmentMark: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    /// Sets its view to display the given message.
    /// If the message is nil, all strings shown are empty.
    func updateValues(fromMessage: Message?, mailbox: Mailbox) {
        if let message = fromMessage {
            if let senderName = message.senderName {
                self.senderLabel.stringValue = senderName
            } else {
                self.senderLabel.stringValue = message.sender
            }
            self.subjectLabel.stringValue = message.subject
            self.timeLabel.stringValue = AppSingleton.userDateFormatter.string(from: message.date)
            self.previewLabel.stringValue = message.body.previewVersion
            self.messageId = message.id
            self.doneTick.isHidden = !HistoryManager.doneMessages.contains(message.id)
            self.unreadMark.isHidden = !mailbox.unreadMessages.contains(message.id)
            self.repliedMark.isHidden = !mailbox.replies.map({$0.id}).contains(message.id)
            self.attachmentMark.isHidden = !message.containsAttachments
        } else {
            self.senderLabel.stringValue = ""
            self.subjectLabel.stringValue = ""
            self.timeLabel.stringValue = ""
            self.previewLabel.stringValue = ""
            self.messageId = nil
            doneTick.isHidden = true
            self.unreadMark.isHidden = true
            self.repliedMark.isHidden = true
            self.attachmentMark.isHidden = true
        }
    }
    
}
