# cdk-swift

<picture><img src="https://img.shields.io/badge/status%EF%B8%8F-proof%20of%20concept-blueviolet"></picture>

(Proof of concept) Swift Canister Development Kit for the Internet Computer.

## Usage

```
nix develop
cd Examples/API
cdk-swift-build API
dfx start --clean --host 127.0.0.1:0
```

```
dfx deploy --network http://127.0.0.1:$(dfx info webserver-port) --no-wallet API_backend
```

To debug Wasm in the browser:

```
python3 -m http.server 1234
```

## Known Issues
* Importing `Foundation` produces a Wasm binary that exceeds the file size limit for deployment.
