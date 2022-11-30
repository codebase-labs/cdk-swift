# cdk-swift

Swift Canister Development Kit for the Internet Computer.

## Usage

```
nix develop
```

```
swift build --triple wasm32-unknown-wasi
```

```
wasm-snip-wasi input.wasm --output output.wasm
```

```
ic-wasm --output output.wasm input.wasm shrink
```

```
wasm2wat input.wasm --output output.wat
```

