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


import Foundation

/* 
 * Log handler using Swift's println. 
 */
public class PrintHandler : Handler {
    private var queue = dispatch_queue_create("loki.printhandler", nil)
    
    public init() {}

    private func synchronized(f: Void -> Void) {
        dispatch_sync(queue, f)
    }
    
    public func log(msg: String) {
        // Logging from multiple threads has to be synchronized, here we do it with dispatch_sync.
        synchronized {
            println(msg)
        }
    }
}

/*
 * System log handler using NSLog
 */
public class SystemLogHandler : Handler {
    public init() {}
    
    public func log(msg: String) {
        // No need to synchronize multiple threads, as NSLog does this itself
        NSLog(msg)
    }
}


/* 
 * File log handler
 */
public class FileHandler : Handler {
    private var queue: dispatch_queue_t
    
    let path: String
    let file: NSFileHandle!
    public init?(path: String) {
        self.path = path
        
        let queue_label = "loki.filehandler." + String(format:"%2X", path.hashValue)
        self.queue = dispatch_queue_create(queue_label, nil)
        
        let fm = NSFileManager.defaultManager()
        
        // Create the log file
        if !fm.fileExistsAtPath(path) {
            if !NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil) {
                NSLog("Couldn't create a file %@", path)
                self.file = nil
                return nil
            }
        }
        
        // Open it for wriging
        if let handle =  NSFileHandle(forWritingAtPath: path) {
            self.file = handle
        } else {
            NSLog("Couldn't open a file %@", path)
            self.file = nil
            
            return nil
        }
    }
    
    private func synchronized(f: Void -> Void) {
        dispatch_sync(queue, f)
    }
    
    public func log(msg: String) {
        // Logging from multiple threads has to be synchronized, here we do it with dispatch_sync.
        // String.writeToFile would provide atomic writing, but it buffers writes and doesn't flush.
        // Flushing is essential for logging.

        let line = msg + "\n"
        if let data = line.dataUsingEncoding(NSUTF8StringEncoding) {
            synchronized {
                self.file.writeData(data)
                self.file.synchronizeFile()
            }
        }
    }
}
