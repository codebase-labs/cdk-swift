import IC

public func print(_ message: String) {
    withUnsafePointer(to: message) { src in
      let size = Int32(MemoryLayout.size(ofValue: message))
      IC.debug_print(src, size)
    }
}

// public func time() -> Int64 {
//     IC.time()
// }
