import IC

@_cdecl("time")
public func time() -> Int64 {
    IC.time()
}
