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

class PreferencesController: NSViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var leftDomEyeButton: NSButton!
    @IBOutlet weak var rightDomEyeButton: NSButton!
    @IBOutlet weak var dpiField: NSTextField!
    @IBOutlet weak var eyeTrackerPopUp: NSPopUpButton!
    @IBOutlet weak var drawDebugCircleCheckCell: NSButtonCell!

    // MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create eye tracker selection menu items using the EyeDataProviderType enum
        // and setting the corresponding rawValue to the created item's tag
        for i in 0..<EyeDataProviderType.count {
            let tracker = EyeDataProviderType(rawValue: i)!
            let menuItem = NSMenuItem(title: tracker.description, action: #selector(self.eyeTrackerSelection(_:)), keyEquivalent: "")
            menuItem.tag = i
            eyeTrackerPopUp.menu!.addItem(menuItem)
        }
        
        // select correct menu item
        if let storedTrackerPref = UserDefaults.standard.object(forKey: EyeConstants.prefEyeTrackerType) as? Int {
            eyeTrackerPopUp.select(eyeTrackerPopUp.itemArray[storedTrackerPref])
        }

        if AppSingleton.dominantEye == .left {
            leftDomEyeButton.state = .on
        } else {
            rightDomEyeButton.state = .on
        }
        
        // number formatter for dpi
        let intFormatter = NumberFormatter()
        intFormatter.numberStyle = NumberFormatter.Style.decimal
        intFormatter.allowsFloats = false
        intFormatter.minimum = 0
        dpiField.formatter = intFormatter
        
        let options = [NSBindingOption.continuouslyUpdatesValue: true]
        dpiField.bind(NSBindingName(rawValue: "value"), to: NSUserDefaultsController.shared, withKeyPath: "values." + EyeConstants.prefMonitorDPI, options: options)

        // draw debug circle in overlay
        drawDebugCircleCheckCell.bind(NSBindingName(rawValue: "value"), to: NSUserDefaultsController.shared, withKeyPath: "values." + EyeConstants.prefDrawDebugCircle, options: options)
    }
    
    // MARK: - Actions
    
    @IBAction func eyeTrackerSelection(_ sender: NSMenuItem) {
        guard let selectedTrackerType = EyeDataProviderType(rawValue: sender.tag) else {
            return
        }
        
        let oldTrackerPref = UserDefaults.standard.object(forKey: EyeConstants.prefEyeTrackerType) as! Int
        
        if oldTrackerPref != sender.tag {
            UserDefaults.standard.set(sender.tag, forKey: EyeConstants.prefEyeTrackerType)
            AppSingleton.eyeTracker = selectedTrackerType.associatedTracker
        }
        
    }
    
    @IBAction func dominantButtonPress(_ sender: NSButton) {
        if sender.identifier!.rawValue == "leftDomEyeButton" {
            AppSingleton.dominantEye = .left
        } else if sender.identifier!.rawValue == "rightDomEyeButton" {
            AppSingleton.dominantEye = .right
        } else {
            fatalError("Some unrecognized button was pressed!?")
        }
    }
    
    
}
