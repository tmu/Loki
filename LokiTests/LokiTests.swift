// The MIT License (MIT)
//
// Copyright (c) 2015 Teemu Kurppa
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit
import XCTest
import Loki


/*
 *  Loki unit tests. Note that currently these doesn't assert anything,
 *  you need to manually inspect and verify the log output.
 *  TODO(tmu): proper unit tests, can be done with a FileHandler or a purpose built test log handler
 */
class LokiTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        rootLogger = Logger(config: Config())
    }
    
    func testBasicLogging() {
        Loki.debug("Basic logging")
    }
    
    func testBasicScope() {
        let scope = Loki.function()
        Loki.debug("Basic scope")
    }

    func foo() {
        let scope = Loki.function()
        Loki.debug("inside foo")
        bar()
    }
    
    func bar() {
        let scope = Loki.function()
        Loki.debug("inside bar")
    }

    func testNestedScope() {
        let scope = Loki.function()
        foo()
    }
    
    func testThreadScope() {
        let scope = Loki.function()

        let dispatchExpectation = self.expectationWithDescription("dispatch A")
    
        Loki.debug("starting")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let scope = Loki.scope("dispatch A")
            Loki.debug("in dispatch A")
            self.foo()
            dispatchExpectation.fulfill()
        }
        Loki.debug("waiting for expectations")
        self.waitForExpectationsWithTimeout(2, handler: nil)
        Loki.debug("ending")
    }

    func testModuleWithTrace() {
        rootLogger.config.exclude("LokiTests.swift")
        rootLogger.config.logLevel = .Trace
        let scope = Loki.function()
        simple()
        nested_outer()
    }

    func testModuleWithDebug() {
        rootLogger.config.exclude("LokiTests.swift")
        rootLogger.config.logLevel = .Debug
        let scope = Loki.function()
        simple()
        nested_outer()
    }
    
    func testSyslogHandler() {
        rootLogger.handlers = [SystemLogHandler()]
        let scope = Loki.function()
        simple()
        nested_outer()
    }
    
    func testMultipleHandlers() {
        rootLogger.handlers.append(FileHandler(path:"/tmp/LokiTests.log")!)
        let scope = Loki.function()
        simple()
        nested_outer()
    }
}
