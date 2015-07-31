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

public enum LogLevel : Int {
    case None=0, Error, Warning, Info, Debug, Trace
}

public protocol Handler {
    func log(msg: String)
}


/*
 * Config stores all the configuration options for a Logger.
 * TODO(tmu): maybe better as a struct
 */
public class Config {
    // Configuration options that you want to tweak
    public var logLevel: LogLevel = .Trace

    // Configuration options that you usually don't want to tweak
    public var indentation_per_scope = 2
    public var indentation_character = " "
    public var scope_in_symbol = "->"
    public var scope_out_symbol = "<-"

    // TODO(tmu): should be sets really. Will change when Swift 1.2 is out of beta.
    var include_modules: [String: Void]? = nil
    var exclude_modules: [String: Void]? = nil

    public init() {
    }

    public func include(module: String) {
        if var modules = include_modules {
            modules[module] = ()
            include_modules = modules
        } else {
            include_modules = [module: ()]
        }
    }

    public func exclude(module: String) {
        if var modules = exclude_modules {
            modules[module] = ()
            exclude_modules = modules
        } else {
            exclude_modules = [module: ()]
        }
    }

    private func should_log_file(file: String) -> Bool {
        let module = file.lastPathComponent
        var should = true
        if let modules = include_modules {
            should = modules[module] != nil
        }
        if let modules = exclude_modules {
            should = should && (modules[module] == nil)
        }
        return should
    }

    private func should_indent_scopes(file: String) -> Bool {
        // TODO(tmu): this could be enabled and disabled separately
        return should_log_file(file)
    }

    private func should_log(#level: LogLevel, file: String) -> Bool {
        if level.rawValue > logLevel.rawValue {
            return false
        } else {
            return should_log_file(file)
        }
    }
}

/*
 * Scopestack is a thread-specific object (see scopestack getter in Logger).
 * Currently it stores only the depth of scope stack (for the indentation)
 * but could store the full scope stack, if that turns out to be useful
 */
class Scopestack {
    var scope_depth = 0

    func push() {
        scope_depth += 1
    }

    func pop() {
        scope_depth -= 1
    }
}


/*
 * Logger orchestrates the logging.
 * Actual logging is done by handlers, which there can be several.
 * Scopestack is thread-specific data and is stored in thread-local storage (TLS)
 * using NSThread.threadDictionary.
 */
public class Logger {
    public var config: Config
    public var handlers: [Handler] = [PrintHandler()]

    private let name: String
    private let scopestack_tls_key: String

    public init(config: Config) {
        self.config = config
        self.name = NSUUID().description
        self.scopestack_tls_key = "loki.scopestack." + self.name
    }

    var scopestack: Scopestack {
        let tls = NSThread.currentThread().threadDictionary
        if let callstack = tls[scopestack_tls_key] as? Scopestack {
            return callstack
        } else {
            let callstack = Scopestack()
            tls[scopestack_tls_key] = callstack
            return callstack
        }
    }

    func indentation() -> String {
        let depth = scopestack.scope_depth
        return config.indentation_character.times(config.indentation_per_scope*depth)
    }

    func should_log(#level:LogLevel, file: String) -> Bool {
        return config.should_log(level:level, file: file)
    }

    func log(@autoclosure msg: () -> String) {
        let txt = self.indentation() + msg()
        for handler in handlers {
            handler.log(txt)
        }
    }

    func checked_log(@autoclosure #msg: () -> String, file: String, level: LogLevel) {
        if !config.should_log(level:level, file:file) { return }
        log(msg)
    }

    func scope_in(scope: Scope) {
        if config.should_log(level:.Trace, file:scope.details.file) {
            log(config.scope_in_symbol + scope.details.long_format())
        }
        if config.should_indent_scopes(scope.details.file) {
            scopestack.push()
        }
    }

    func scope_out(scope: Scope) {
        if config.should_indent_scopes(scope.details.file) {
            scopestack.pop()
        }
        if config.should_log(level:.Trace, file:scope.details.file) {
            log(config.scope_out_symbol + scope.details.long_format())
        }
    }

    public func error(@autoclosure msg : () -> String, file: String = __FILE__) -> () {
        checked_log(msg: msg, file: file, level: .Error)
    }

    public func warning(@autoclosure msg : () -> String, file: String = __FILE__) -> () {
        checked_log(msg: msg, file: file, level: .Warning)
    }

    public func info(@autoclosure msg : () -> String, file: String = __FILE__) -> () {
        checked_log(msg: msg, file: file, level: .Info)
    }

    public func debug(@autoclosure msg : () -> String, file: String = __FILE__) -> () {
        checked_log(msg: msg, file: file, level: .Debug)
    }

    public func trace(@autoclosure msg : () -> String, file: String = __FILE__) -> () {
        checked_log(msg: msg, file: file, level: .Trace)
    }

    public func function(
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: Int = __LINE__,
        column: Int = __COLUMN__) -> Scope? {
        if config.should_indent_scopes(file) {
            return Scope(logger: self, function: function, file: file, line: line, column: column)
        } else {
            return nil
        }
    }

    public func scope(name: String,
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: Int = __LINE__,
        column: Int = __COLUMN__) -> Scope?
    {
        if config.should_indent_scopes(file) {
            return Scope(logger: self, name: name,
                         function: function, file: file, line: line, column: column)
        } else {
            return nil
        }
    }
}

public class Scope {
    struct Details {
        let module: String
        let name: String
        let thread_id: mach_port_t
        let isMainThread: Bool

        let function: String
        let file: String
        let line: Int
        let column: Int


        func long_format() -> String {
            if isMainThread {
                return "[main] \(module):\(line) \(function) \(name)"
            } else {
                return "[\(thread_id)] \(module):\(line) \(function) \(name)"
            }
        }
    }

    let details: Details
    let logger: Logger

    init(
        logger: Logger,
        name: String = String(),
        function: String,
        file: String,
        line: Int,
        column: Int) {
            self.logger = logger
            // TODO(tmu): Get a thread id once for a thread-specific logger
            let thread_id = pthread_mach_thread_np(pthread_self())
            // TODO(tmu): Better module names with something like project root relative paths
            let module = file.lastPathComponent
            details = Details(module: module, name: name, thread_id: thread_id, isMainThread: NSThread.isMainThread(),
                              function:function, file:file, line:line, column:column)
            logger.scope_in(self)
    }

    deinit {
        logger.scope_out(self)
    }
}

public var rootLogger = Logger(config: Config())

#if LOKI_ON
    public struct Loki {
        public static func error(@autoclosure msg: () -> String, file: String = __FILE__) {
            rootLogger.error(msg, file:file)
        }

        public static func warning(@autoclosure msg: () -> String, file: String = __FILE__) {
            rootLogger.warning(msg, file:file)
        }

        public static func info(@autoclosure msg: () -> String, file: String = __FILE__) {
            rootLogger.info(msg, file:file)
        }

        public static func debug(@autoclosure msg: () -> String, file: String = __FILE__) {
            rootLogger.debug(msg, file:file)
        }

        public static func trace(@autoclosure msg: () -> String, file: String = __FILE__) {
            rootLogger.trace(msg, file:file)
        }

        public static func function(function: String = __FUNCTION__,
            file: String = __FILE__,
            line: Int = __LINE__,
            column: Int = __COLUMN__) -> Scope?
        {
            return rootLogger.function(function: function, file:file, line:line, column:column)
        }

        public static func scope(
            name: String,
            function: String = __FUNCTION__,
            file: String = __FILE__,
            line: Int = __LINE__,
            column: Int = __COLUMN__) -> Scope?
        {
            return rootLogger.scope(name, function: function,
                                file:file, line:line, column:column)
        }
    }
#else
    public struct Loki {
        public static func error(@autoclosure msg: () -> String, file: String = __FILE__) {
        }

        public static func warning(@autoclosure msg: () -> String, file: String = __FILE__) {
        }

        public static func info(@autoclosure msg: () -> String, file: String = __FILE__) {
        }

        public static func debug(@autoclosure msg: () -> String, file: String = __FILE__) {
        }

        public static func trace(@autoclosure msg: () -> String, file: String = __FILE__) {
        }

        public static func function(function: String = __FUNCTION__,
            file: String = __FILE__,
            line: Int = __LINE__,
            column: Int = __COLUMN__) -> Scope?
        {
            return nil
        }

        public static func scope(
            name: String,
            function: String = __FUNCTION__,
            file: String = __FILE__,
            line: Int = __LINE__,
            column: Int = __COLUMN__) -> Scope?
        {
            return nil
        }
    }
#endif
