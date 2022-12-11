# cdk-swift

Swift Canister Development Kit for the Internet Computer.

## Usage

```
nix develop
```

```
swift build -c release --triple wasm32-unknown-wasi
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

```
gzip --to-stdout --best input.wasm > output.wasm.gz
```
