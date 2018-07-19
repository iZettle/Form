//
//  ExampleUITests.swift
//  ExampleUITests
//
//  Created by Laszlo Pinter on 2018. 07. 06..
//  Copyright © 2018. iZettle. All rights reserved.
//

import XCTest

class ExampleUITests: XCTestCase {
    let app = XCUIApplication()
    let testString = "Hello UITests"
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    //    Reverts the field values to the starting states. Call this among steps.
    func cleanUp() {
        //Make sure that the fields are empty
        let deleteTestString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: testString.count)
        app.textFields["secondField"].tap()
        app.typeText(deleteTestString)
        
        app.textFields["thirdField"].tap()
        app.typeText(deleteTestString)
        
        // Select the first field
        app.textFields["firstField"].tap()
    }
    
    func testBorderTaps() {
        XCTContext.runActivity(named: "CheckingTopLeftCornerTap") { _ in
            verifyTopLeftCornerTap()
            cleanUp()
            verifyBottomRightCornerTap()
            cleanUp()
            verifyTappingSwitchInARowDoesntSelectField()
        }
    }
    
    func verifyTopLeftCornerTap() {
        XCTContext.runActivity(named: "CheckingTopLeftCornerTap") { _ in
            app.otherElements["secondRow"].coordinate(withNormalizedOffset: CGVector.zero).tap()
            app.typeText(testString)
            let secondField = app.textFields["secondField"]
            
            XCTAssertEqual(secondField.value as! String, testString)
        }
    }
    
    func verifyBottomRightCornerTap() {
        XCTContext.runActivity(named: "CheckingTopLeftCornerTap") { _ in
            
            app.otherElements["secondRow"].coordinate(withNormalizedOffset: CGVector.init(dx: 0.99, dy: 0.99)).tap()
            app.typeText(testString)
            let secondField = app.textFields["secondField"]
            
            XCTAssertEqual(secondField.value as! String, testString)
        }
    }
    
    func verifyTappingSwitchInARowDoesntSelectField() {
        app.switches["switch"].tap()
        app.typeText(testString)
        let thirdField = app.textFields["thirdField"]
        XCTAssertEqual(thirdField.value as! String, "")
    }
    
    func testTappingRowOfValueField() {
        app.otherElements["secondRow"].coordinate(withNormalizedOffset: CGVector.zero).tap()
        
        app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.otherElements["valueField"]/*[[".otherElements[\"valueRow\"].otherElements[\"valueField\"]",".otherElements[\"valueField\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        let key = app/*@START_MENU_TOKEN@*/.keys["1"]/*[[".keyboards.keys[\"1\"]",".keys[\"1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        key.tap()
        
        let key2 = app/*@START_MENU_TOKEN@*/.keys["9"]/*[[".keyboards.keys[\"9\"]",".keys[\"9\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        key2.tap()
        key2.tap()
        key.tap()
        

        let valueField = app.otherElements["valueField"]
        
        XCTAssertEqual(valueField.value as! String, "1,991")
    }
}
