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

class ServerConnectController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var datePicker: NSDatePicker!
    @IBOutlet weak var addressField: NSTextField!
    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var clearPasswordField: NSTextField!
    
    @IBOutlet weak var resultLabel: NSTextField!
    @IBOutlet weak var showButton: NSButton!
    @IBOutlet weak var flagRepliedButton: NSButton!
    @IBOutlet weak var doNotCommunicateReadMessages: NSButton!
    @IBOutlet weak var connectButton: NSButton!
    @IBOutlet weak var connectIndicator: NSProgressIndicator!
    
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        self.addressField.stringValue = UserDefaults.standard.object(forKey: Constants.kServer) as? String ?? ""
        self.usernameField.stringValue = UserDefaults.standard.object(forKey: Constants.kUsername) as? String ?? ""
        self.datePicker.dateValue = UserDefaults.standard.object(forKey: Constants.kSinceDate) as? Date ?? Constants.defaultSinceDate
        self.tableView.delegate = self
        self.tableView.dataSource = self
        tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(checkText(_:)), name: NSControl.textDidChangeNotification, object: self.passwordField)
        NotificationCenter.default.addObserver(self, selector: #selector(checkText(_:)), name: NSControl.textDidChangeNotification, object: self.clearPasswordField)
    }
    
    @IBAction func connectPress(_ sender: AnyObject) {
        
        DispatchQueue.main.async {
            
            // make sure we store data from now on
            HistoryManager.demoing = false
            
            self.connectButton.isEnabled = false
            self.connectIndicator.startAnimation(nil)
            let _password = self.showButton.state == .on ? self.clearPasswordField.stringValue : self.passwordField.stringValue
            let password = _password.trimmingCharacters(in: .whitespaces)
            let flagReplied = self.flagRepliedButton.state == .on
            let dontTouchUnread = self.doNotCommunicateReadMessages.state == .on

            UserDefaults.standard.set(self.usernameField.stringValue, forKey: Constants.kUsername)
            UserDefaults.standard.set(self.addressField.stringValue, forKey: Constants.kServer)
            UserDefaults.standard.set(self.datePicker.dateValue, forKey: Constants.kSinceDate)
            
            let connectionDetails = ServerDetails(address: self.addressField.stringValue, username: self.usernameField.stringValue, password: password, sinceDate: self.datePicker.dateValue, flagReplied: flagReplied, dontTouchUnread: dontTouchUnread)
            
            self.saveRecentImapIfNeeded(connectionDetails.address)
            self.tableView.reloadData()
            
            // load mbox in background
            DispatchQueue.global(qos: .userInitiated).async {
                [unowned self] in
                
                do {
                    try (NSApplication.shared.delegate as? AppDelegate)?.loadCurlBox(serverWithDetails: connectionDetails)
                    DispatchQueue.main.async {
                        [unowned self] in
                        self.view.window?.close()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.resultLabel.stringValue = error.localizedDescription
                        self.connectButton.isEnabled = true
                        self.connectIndicator.stopAnimation(nil)
                    }

                }
                
            }
            
        }
        
    }
    
    @IBAction func showPress(_ sender: NSButton) {
        DispatchQueue.main.async {
            if sender.state == .off {
                self.passwordField.stringValue = self.clearPasswordField.stringValue
                let moveFocus = self.view.window!.firstResponder === self.clearPasswordField.innerTextView
                self.passwordField.isHidden = false
                self.clearPasswordField.isHidden = true
                if moveFocus {
                    self.passwordField.becomeFirstResponder()
                }
            } else {
                self.clearPasswordField.stringValue = self.passwordField.stringValue
                let moveFocus = self.view.window!.firstResponder === self.passwordField.innerTextView
                self.clearPasswordField.isHidden = false
                self.passwordField.isHidden = true
                if moveFocus {
                    self.clearPasswordField.becomeFirstResponder()
                }
            }
        }
    }
    
    @IBAction func encryptAllPress(_ sender: NSButton) {
        AppSingleton.hashEverything = sender.state == .on
    }
    
    /// Enables connect if there's some text everywhere
    @objc func checkText(_ notification: Notification) {
        let pass: String
        if self.passwordField.isHidden {
            pass = self.clearPasswordField.stringValue
        } else {
            pass = self.passwordField.stringValue
        }
        DispatchQueue.main.async {
            self.connectButton.isEnabled = pass.trimmingCharacters(in: .whitespaces).count > 0
            self.resultLabel.stringValue = ""
        }
    }
    
    private func saveRecentImapIfNeeded(_ imapaddr: String) {
        guard imapaddr.count > 0 else {
            return
        }
        
        var recents = UserDefaults.standard.object(forKey: Constants.kRecentImaps) as! [String]
        if let i = recents.index(of: imapaddr) {
            recents.remove(at: i)
            recents.insert(imapaddr, at: 0)
        } else {
            recents.insert(imapaddr, at: 0)
            if recents.count > Constants.recentImapsMaxNum {
                recents.removeSubrange(Constants.recentImapsMaxNum..<recents.count)
            }
        }
        
        UserDefaults.standard.set(recents, forKey: Constants.kRecentImaps)
    }
    
    // MARK: - TableViewDelegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let recents = UserDefaults.standard.object(forKey: Constants.kRecentImaps) as? [String] else {
            return
        }
        
        DispatchQueue.main.async {
            if self.tableView.selectedRow >= 0 {
                let addr = recents[self.tableView.selectedRow]
                self.addressField.stringValue = addr
                if let v = Constants.imapUsernameAppendages[addr] {
                    var cuser = self.usernameField.stringValue
                    if !cuser.contains(v) {
                        cuser += v
                        self.usernameField.stringValue = cuser
                    }
                }
            }
        }
    }
    
    // MARK: - TableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let recents = UserDefaults.standard.object(forKey: Constants.kRecentImaps) as? [String] else {
            return 0
        }
        return recents.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let recents = UserDefaults.standard.object(forKey: Constants.kRecentImaps) as? [String], row >= 0 else {
            return 0
        }
        return recents[row]
    }
    
}
