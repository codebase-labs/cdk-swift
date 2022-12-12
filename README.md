# cdk-swift

Swift Canister Development Kit for the Internet Computer.

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
