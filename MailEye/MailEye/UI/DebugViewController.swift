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
import AppKit

class DebugViewController: NSViewController {
    
    var window: NSWindow!
    
    let maxBuff = 20
    
    /// Just append individual strings to this
    var topBuffer = [String]() { didSet {
        DispatchQueue.main.async {
            self.topText.string = self.topBuffer.joined(separator: "\n")
            self.topText.scrollToEndOfDocument(nil)
        }
        if topBuffer.count > maxBuff {
            topBuffer.remove(at: 0)
        }
    } }
    
    /// Just append invidual strings to this
    var bottomBuffer = [String]() { didSet {
        DispatchQueue.main.async {
            self.bottomText.string = self.bottomBuffer.joined(separator: "\n")
            self.bottomText.scrollToEndOfDocument(nil)
        }
        if bottomBuffer.count > maxBuff {
            bottomBuffer.remove(at: 0)
        }
    } }
    
    @IBOutlet var topText: NSTextView!

    @IBOutlet var bottomText: NSTextView!
    
}
