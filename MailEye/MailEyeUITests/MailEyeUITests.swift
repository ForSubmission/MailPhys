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

import XCTest

class MailEyeUITests: XCTestCase {
    
    static var numOfReplies = 0
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        MailEyeUITests.numOfReplies = 0
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        XCUIApplication()/*@START_MENU_TOKEN@*/.windows["MailEye"]/*[[".windows[\"MailEye\"]",".windows[\"MainWindow\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.buttons[XCUIIdentifierCloseWindow].click()
        sleep(1)

    }
    
    /// Replies to a lot of mbox messages
    func testMboxLotsOfReplies() {
        let app = XCUIApplication()
        let connectToServerWindow = app.windows["Connect to server"]
        
        connectToServerWindow.buttons[XCUIIdentifierCloseWindow].click()
        
        let testMboxURL = Bundle(for: type(of: self)).url(forResource: "mbox", withExtension: "")
        let textToEnter = testMboxURL!.relativePath
        
        let menuBarsQuery = app.menuBars
        menuBarsQuery/*@START_MENU_TOKEN@*/.menuItems["Open…"]/*[[".menuBarItems[\"File\"]",".menus.menuItems[\"Open…\"]",".menuItems[\"Open…\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.click()
        
        app.dialogs["Open"].typeKey("g", modifierFlags:[.command, .shift])

        let xsidebarheaderCell = app/*@START_MENU_TOKEN@*/.outlines["sidebar"]/*[[".dialogs[\"Open\"]",".groups",".splitGroups",".scrollViews.outlines[\"sidebar\"]",".outlines[\"sidebar\"]"],[[[-1,4],[-1,3],[-1,2,3],[-1,1,2],[-1,0,1]],[[-1,4],[-1,3],[-1,2,3],[-1,1,2]],[[-1,4],[-1,3],[-1,2,3]],[[-1,4],[-1,3]]],[0]]@END_MENU_TOKEN@*/.children(matching: .outlineRow).element(boundBy: 0).cells.containing(.staticText, identifier:"xSidebarHeader").element
        
        xsidebarheaderCell.typeText(textToEnter)
        app.sheets.buttons["Go"].click()
        XCUIApplication().dialogs["Open"].buttons["Open"].click()

        let mainwindowWindow = app/*@START_MENU_TOKEN@*/.windows["MailEye"]/*[[".windows[\"MailEye\"]",".windows[\"MainWindow\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/
        let messageTable = mainwindowWindow.tables.firstMatch
        
        sleep(3)
        
        let replyToPredicate = NSPredicate(format: "title BEGINSWITH %@", "Reply to")
        
        for i in 0..<35 {
            
            // go to next row and press reply
            messageTable.tableRows.element(boundBy: i).click()
            mainwindowWindow.buttons["Reply / Note"].click()
            
            let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short)
            
            // create reply
            
            let replyWindow = app.windows.element(matching: replyToPredicate)
            replyWindow.click()
            replyWindow.scrollViews.firstMatch.typeText("I'm typing this on \(dateString)")
            replyWindow.buttons["Close and Save"].click()
            
        }
        
    }
    
    /// Tests a demo, which should NOT output anything in Downloads
    func testDemo() {
        let app = XCUIApplication()
        
        let menuBarsQuery = app.menuBars
        menuBarsQuery.menuBarItems["File"].click()
        menuBarsQuery/*@START_MENU_TOKEN@*/.menuBarItems["File"].menuItems["Demo"]/*[[".menuBarItems[\"File\"]",".menus.menuItems[\"Demo\"]",".menuItems[\"Demo\"]",".menus.containing(.menuItem, identifier:\"Print…\").menuItems[\"Demo\"]",".menus.containing(.menuItem, identifier:\"Page Setup…\").menuItems[\"Demo\"]",".menus.containing(.menuItem, identifier:\"Save As…\").menuItems[\"Demo\"]",".menus.containing(.menuItem, identifier:\"Save…\").menuItems[\"Demo\"]",".menus.containing(.menuItem, identifier:\"Close All\").menuItems[\"Demo\"]",".menus.containing(.menuItem, identifier:\"Close\").menuItems[\"Demo\"]",".menus.containing(.menuItem, identifier:\"Open Recent\").menuItems[\"Demo\"]",".menus.containing(.menuItem, identifier:\"Open server...\").menuItems[\"Demo\"]",".menus.containing(.menuItem, identifier:\"Open…\").menuItems[\"Demo\"]",".menus.containing(.menuItem, identifier:\"New\").menuItems[\"Demo\"]"],[[[-1,12],[-1,11],[-1,10],[-1,9],[-1,8],[-1,7],[-1,6],[-1,5],[-1,4],[-1,3],[-1,0,1]],[[-1,2],[-1,1]]],[10,0]]@END_MENU_TOKEN@*/.click()
        
        let examples = findExamples()  // should return two items
        
        examples?.element(boundBy: 1).click()
        
        replyToMessage(text: "Writing a message that should NOT be saved")
        
    }
    
    /// Tests a "normal" connection to curlbox, which should output some data in Downloads
    func testCurlBoxWithReplyAndDone() {
        let app = XCUIApplication()
        
        let connectToServerWindow = app.windows["Connect to server"]
        
        let firstTextField = connectToServerWindow.textFields.element(boundBy: 0)
        firstTextField.click()
        firstTextField.typeKey("a", modifierFlags: .command)
        firstTextField.typeText(Constants.publicServerDetails.address)
        
        let secondTextField = connectToServerWindow.textFields.element(boundBy: 1)
        secondTextField.click()
        secondTextField.typeKey("a", modifierFlags: .command)
        secondTextField.typeText(Constants.publicServerDetails.username)
        
        connectToServerWindow.children(matching: .secureTextField).element.click()
        connectToServerWindow.children(matching: .secureTextField).element
            .typeText(Constants.publicServerDetails.password)
        
        let dontSetRead = connectToServerWindow.checkBoxes["Do not set messages as read on server"].firstMatch
        let setFlag = connectToServerWindow.checkBoxes["Flag replied messages"].firstMatch
 
        // click on don't set read if the checkbox is not enabled
        if dontSetRead.value as! Bool == false {
            dontSetRead.click()
        }
        
        // deactivate set flag if it is on
        if setFlag.value as! Bool == true {
            setFlag.click()
        }
        
        connectToServerWindow.buttons["Connect"].click()
        
        let mailboxWindow = app/*@START_MENU_TOKEN@*/.windows["MailEye"]/*[[".windows[\"MailEye\"]",".windows[\"MainWindow\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/
        let toolbarsQuery = mailboxWindow.toolbars
        
        let examples = findExamples() // should return two items
        
        // do first example
        
        examples?.element(boundBy: 0).click()
        
        replyToMessage(text: "Writing a message that should be saved")
        
        toolbarsQuery.buttons["Done"].click()

        // queries for tagging message
        let sheetsQuery = mailboxWindow.sheets
        let priorityGroupQuery = sheetsQuery.groups.containing(.radioButton, identifier: "Top")
        let pleasureGroupQuery = sheetsQuery.groups.containing(.radioButton, identifier: "Unpleasant")
        let workloadGroupsQuery = sheetsQuery.groups.containing(.radioButton, identifier: "High")
        
        priorityGroupQuery.children(matching: .radioButton).element(boundBy: 3).click()
        pleasureGroupQuery.children(matching: .radioButton).element(boundBy: 3).click()
        workloadGroupsQuery.children(matching: .radioButton).element(boundBy: 3).click()
        
        sheetsQuery.buttons["Done"].click()
        
        // do second example
        
        examples?.element(boundBy: 1).click()
        
        replyToMessage(text: "Writing another message that should be saved")

        toolbarsQuery.buttons["Done"].click()
        
        priorityGroupQuery.children(matching: .radioButton).element(boundBy: 1).click()
        pleasureGroupQuery.children(matching: .radioButton).element(boundBy: 1).click()
        workloadGroupsQuery.children(matching: .radioButton).element(boundBy: 1).click()
        
        sheetsQuery.buttons["Done"].click()

    }
    
    private func replyToMessage(text: String) {
        let app = XCUIApplication()
        let mailboxWindow = app/*@START_MENU_TOKEN@*/.windows["MailEye"]/*[[".windows[\"MailEye\"]",".windows[\"MainWindow\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/
        let toolbarsQuery = mailboxWindow.toolbars
        toolbarsQuery.buttons["Reply / Note"].click()
        let replyWindowQuery = app.windows.matching(NSPredicate(format: "title BEGINSWITH 'Reply to'"))
        let replyWindow = replyWindowQuery.element(boundBy: 0)
        let textView = replyWindow.scrollViews.children(matching: .textView).element
        textView.typeText("\(text)")
        textView.typeKey(.enter, modifierFlags: [])
        MailEyeUITests.numOfReplies += 1
        textView.typeText("Reply number \(MailEyeUITests.numOfReplies).")
        replyWindow.buttons["Close and Save"].click()
    }
    
    private func findExamples() -> XCUIElementQuery? {
        let app = XCUIApplication()

        let mainwindowWindow = app/*@START_MENU_TOKEN@*/.windows["MailEye"]/*[[".windows[\"MailEye\"]",".windows[\"MainWindow\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/
        
        if mainwindowWindow.waitForExistence(timeout: 20) == false {
            XCTFail("Mailbox window did not appear")
            return nil
        }
        
        let messagesTable = mainwindowWindow.tables.firstMatch
        let tableHasRows = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count > 3"), object: messagesTable.tableRows)
        
        wait(for: [tableHasRows], timeout: 20)
        
        let expectedText = "Example"
        
        // find items which contain the expected string (two example messages)
        // note: make sure you use value instead of title or label in predicate
        let expectedItems = messagesTable.staticTexts.matching(NSPredicate(format: "placeholderValue = 'Subject' AND value CONTAINS %@", expectedText))
        
        let twoExpectedItems = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count >= 2"), object: expectedItems)
        
        wait(for: [twoExpectedItems], timeout: 30)
        
        return expectedItems
    }
    
}
