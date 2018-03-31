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

import os.log
import Cocoa
import ZipArchive

enum SaveError: Swift.Error, LocalizedError {
        
        var errorDescription: String? { get {
            switch self {
            case .writeError(let internalError):
                return "Failed to write file: \(internalError.localizedDescription)"
            case .stringError:
                return "Failed to create output string"
            case .fontError:
                return "Failed reference font for writing"
            }
        } }
        
    case writeError(Swift.Error)
    case stringError
    case fontError
}

extension Mailbox {
    
    /// Saves all replies to a rtf file.
    /// If this was a curlbox, password-protects zip file and deletes all rtf files upon successful completion.
    /// If zipping is successful, all old replies are deleted.
    func saveAllReplies() throws {
        guard let bodyFont = NSFont(name: "Helvetica", size: 12) else {
            throw SaveError.fontError
        }
        
        let fullString = NSMutableAttributedString()
        let attributes = [NSAttributedStringKey.font: bodyFont]
        let separator = NSAttributedString(string: "\n\n\n", attributes: attributes)

        for i in 0..<replies.count {
            let substring = try makeReplyText(replyId: replies[i].id)
            fullString.append(substring)
            // append separator unless it's the last one
            if i != replies.count - 1 {
                fullString.append(separator)
            }
        }
        
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short)
        let allRepliesBasename = folder.appendingPathComponent("All replies \(dateString)")
        let allRepliesRtfFile = allRepliesBasename.appendingPathExtension("rtf")
        let r = NSRange(location: 0, length: fullString.length)
        let allRepliesData = try fullString.data(from: r, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        try allRepliesData.write(to: allRepliesRtfFile)
        
        
        if let cbox = self as? CurlBox {
            let password = cbox.serverDetails.password
            let allRepliesZipFile = folder.appendingPathComponent("\(cbox.serverDetails.username) \(dateString)").appendingPathExtension("zip")
            do {
                // make zip
                SSZipArchive.createZipFile(atPath: allRepliesZipFile.path, withFilesAtPaths: [allRepliesRtfFile.path], withPassword: password)
                
                // delete all rtf files
                let urls = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.typeIdentifierKey], options: .skipsSubdirectoryDescendants)
                try urls.forEach() {
                    if try $0.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier ?? "" == "public.rtf" {
                        try FileManager.default.removeItem(at: $0.absoluteURL)
                    }
                }
                
            } catch {
                AppSingleton.alertUser("Failure during password protected zip save or delete operation", infoText: error.localizedDescription)
            }
        }
        
    }
    
    /// Saves a reply (or note) associated to the given message id to disk.
    func saveReply(_ replyId: String) throws {
        
        let filename = folder.appendingPathComponent(replyId + ".rtf")
        
        let attString = try makeReplyText(replyId: replyId)
        
        let r = NSRange(location: 0, length: attString.length)
        let data = try attString.data(from: r, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        
        try data.write(to: filename)
        
    }
    
    /// Returns the textual representation of a reply,
    /// containing message "headers" and the reply itself.
    /// Returns an empty string if the operation failed (should never happen).
    private func makeReplyText(replyId: String) throws -> NSAttributedString {
        guard let i = replies.index(where: {$0.id == replyId}),
              let msgI = messageIndex[replyId],
              msgI < allMessages.count, let message = allMessages[msgI] else {
            if #available(OSX 10.12, *) {
                os_log("Couldn't find reply for: %@", type: .error, replyId)
            }
            throw SaveError.stringError
        }
        
        guard let senderNameFont = NSFont(name: "Helvetica-Bold", size: 16),
              let senderFont = NSFont(name: "Helvetica-Bold", size: 12),
              let bodyFont = NSFont(name: "Helvetica", size: 12),
              let subjectFont = NSFont(name: "Helvetica", size: 14) else {
            throw SaveError.fontError
        }
        
        let text = replies[i].reply
        
        // sender address (bold, goes after sender name, if present)
        var attributes = [NSAttributedStringKey.font: senderFont]
        var string = NSMutableAttributedString(string: message.sender + "\n", attributes: attributes)
        
        // sender name (bold)
        if let senderName = message.senderName {
            attributes = [NSAttributedStringKey.font: senderNameFont]
            let senderNameString = NSMutableAttributedString(string: senderName + "\n", attributes: attributes)
            senderNameString.append(string)
            string = senderNameString
        }
        
        // date
        attributes = [NSAttributedStringKey.font: bodyFont]
        let dateString = NSAttributedString(string: AppSingleton.userDateFormatter.string(from: message.date) + "\n", attributes: attributes)
        string.append(dateString)
        
        // attachments
        if message.containsAttachments {
            let attachmentString = NSAttributedString(string: "Attachment(s)" + "\n", attributes: attributes)
            string.append(attachmentString)
        }
        
        // corrupted
        if HistoryManager.corruptedMessages.contains(message.id) {
            attributes = [NSAttributedStringKey.font: subjectFont]
            let corruptedString = NSAttributedString(string: "CORRUPTED" + "\n", attributes: attributes)
            string.append(corruptedString)
        }
        
        
        // subject
        attributes = [NSAttributedStringKey.font: subjectFont]
        let subjectString = NSAttributedString(string: message.subject + "\n\n", attributes: attributes)
        string.append(subjectString)
        
        // body
        attributes = [NSAttributedStringKey.font: bodyFont]
        let replyString = NSAttributedString(string: text, attributes: attributes)
        string.append(replyString)
        
        return string
    }
    
}
