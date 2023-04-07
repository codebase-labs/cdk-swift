import IC

public func print(_ message: String) {
    message.withCString { body in
        let size = Int32(message.utf8.count)
        IC.ic0_debug_print(body, size)
    }
}

public func time() -> UInt64 {
    IC.ic0_time()
}
