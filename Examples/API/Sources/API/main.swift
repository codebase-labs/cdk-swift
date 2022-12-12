import CDK

@_cdecl("canister_init")
func `init`() {
    CDK.print("Hello from Swift!")
}
