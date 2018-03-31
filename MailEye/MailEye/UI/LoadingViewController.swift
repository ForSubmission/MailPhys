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

class LoadingViewController: NSViewController {
    
    /// Strings that are displayed representing handled errors.
    /// Just append strings to be displayed.
    private(set) var errorBuffer = [String]() { didSet {
        DispatchQueue.main.async {
            [unowned self] in
            self.errorDescriptions.string = self.errorBuffer.joined(separator: "\n")
            self.errorDescriptions.scrollToEndOfDocument(nil)
            self.errorsLabel.stringValue = "Errors: (\(self.errorBuffer.count))"
        }
    } }
    
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var errorsLabel: NSTextField!
    @IBOutlet var errorDescriptions: NSTextView!
    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    
    var observation: NSKeyValueObservation!
    
    override func viewDidLoad() {
        DispatchQueue.main.async {
            self.progressBar.startAnimation(self)
        }
    }
    
    weak var progress: Progress! { didSet {
        
        DispatchQueue.main.async {
            self.cancelButton.isEnabled = true
        }
        
        self.observation  = progress.observe(\.completedUnitCount) {
            progress, _ in
            
            DispatchQueue.main.async {
                if self.progressBar.isIndeterminate {
                    DispatchQueue.main.async {
                        self.progressBar.isIndeterminate = false
                    }
                }
                
                self.progressBar.doubleValue = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                self.progressLabel.stringValue = progress.localizedDescription
                if progress.completedUnitCount >= progress.totalUnitCount {
                    DispatchQueue.main.async {
                        self.closeButton.isEnabled = true
                        self.cancelButton.isEnabled = false
                        if self.errorBuffer.count == 0 && !self.progress.isCancelled {
                            self.view.window?.close()
                        }
                    }
                }
            }
        }
    }}
    
    @IBAction func cancelPressed(_ sender: NSButton) {
        progress.cancel()
        DispatchQueue.main.async {
            self.cancelButton.isEnabled = false
            self.closeButton.isEnabled = true
        }
    }
    
    @IBAction func closePressed(_ sender: NSButton) {
        DispatchQueue.main.async {
            self.view.window?.close()
        }
    }
    
    func loadFailure(_ message: String) {
        DispatchQueue.main.async {
            self.progressBar.isIndeterminate = false
            self.cancelButton.isEnabled = false
            self.closeButton.isEnabled = true
            self.progressLabel.stringValue = "Load failed"
            self.errorBuffer.append("Failed to load mailbox: \(message)")
        }
    }
    
    func loadingComplete() {
        DispatchQueue.main.async {
            self.cancelButton.isEnabled = false
        }
    }
    
    func displayError(_ error: Swift.Error, _ i: Int?) {
        let prefix = i == nil ? "" : "\(i!) "
        errorBuffer.append(prefix + error.localizedDescription)
    }
    
}
