import CDK
// import Foundation

@_cdecl("canister_init")
func `init`() {
    CDK.print("Hello from Swift!")

    CDK.print("time: \(CDK.time())")

    // let timeInterval = Double(CDK.time() / 1_000_000_000)
    // let date = Date(timeIntervalSince1970: timeInterval)
    // CDK.print("date: \(date)")
}
