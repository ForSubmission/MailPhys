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

class ReplyController: NSViewController, NSTextViewDelegate {
    
    // MARK: - Internal properties
    
    @IBOutlet weak var replyTextView: NSTextView!
    @IBOutlet weak var subjectLabel: NSTextField!
    
    // MARK: - Set by segue
    
    var replyToId: String?
    
    /// Once mailbox is set, the controller updates its state
    weak var mailbox: Mailbox? { didSet {
        if let id = self.replyToId,
           let message = mailbox?.getMessage(forId: id)  {
            DispatchQueue.main.async {
                [weak self] in
                // update title and subject
                self?.subjectLabel.stringValue = message.subject
                if let senderName = message.senderName {
                    self?.title = "Reply to \(senderName)"
                } else {
                    self?.title = "Reply to \(message.sender)"
                }
                // update reply text, if any
                if let i = self?.mailbox?.replies.index(where: {$0.id == id}) {
                    self?.replyTextView.string = self?.mailbox?.replies[i].reply ?? ""
                }
            }
        }
    } }

    // MARK: - Actions
    
    @IBAction func cancelPress(_ sender: NSButton) {
        guard !replyTextView.string.isEmpty else {
            self.view.window?.performClose(nil)
            return
        }
        
        guard let window = self.view.window else {
            return
        }
        
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Cancel current reply?"
        alert.informativeText = "Text will be deleted"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        DispatchQueue.main.async {
            alert.beginSheetModal(for: window) {
                response in
                if response == .alertFirstButtonReturn {
                    DispatchQueue.main.async {
                        [weak self] in
                        self?.replyTextView.string = ""
                        self?.view.window?.performClose(nil)
                    }
                }
            }
        }
    }
    
    @IBAction func closePress(_ sender: NSButton) {
        self.view.window?.performClose(nil)
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let font = NSFont(name: "Monaco", size: 14)!
        self.replyTextView.font = font
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        // "save" our contents before disappearing
        guard let id = self.replyToId else {
            return
        }
        
        // if the text is empty, otherwise save
        if self.replyTextView.string.isEmpty {
            mailbox?.removeReply(forId: id)
        } else {
            mailbox?.addReply(id: id, reply: self.replyTextView.string)
        }
    }
    
    // MARK: - Text delegate
    
    func textDidChange(_ notification: Notification) {
        guard let id = replyToId else {
            return
        }
        if HistoryManager.replyTimes[id] == nil {
            HistoryManager.replyTimes[id] = Date().unixTime
        }
    }
    
}
