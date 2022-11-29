{
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:stephank/nixpkgs?ref=feat/swift-darwin";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dfinity-sdk = {
      url = "github:paulyoung/nixpkgs-dfinity-sdk?rev=28bb54dc1912cd723dc15f427b67c5309cfe851e";
      flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";

    ic-repl-src = {
      url = "github:chenyan2002/ic-repl";
      flake = false;
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    crane,
    dfinity-sdk,
    flake-utils,
    ic-repl-src,
    rust-overlay,
    ...
  }:
    let
      supportedSystems = [
        flake-utils.lib.system.aarch64-darwin
        flake-utils.lib.system.x86_64-darwin
      ];
    in
      flake-utils.lib.eachSystem supportedSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (final: prev: (import dfinity-sdk) final prev)
              (import rust-overlay)
            ];
          };

          dfinitySdk = (pkgs.dfinity-sdk {
            acceptLicenseAgreement = true;
            sdkSystem = system;
          }).makeVersion {
            systems = {
              "x86_64-darwin" = {
                sha256 = "sha256-5F70Hc57NSEuOadM8/ZnFXKGzBmazdU044cNpQmQhDI=";
              };
            };
            version = "0.12.0-beta.2";
          };

          rust = pkgs.rust-bin.stable.latest.default;
          # rust = pkgs.rust-bin.nightly."2022-06-01".default;

          # NB: we don't need to overlay our custom toolchain for the *entire*
          # pkgs (which would require rebuilding anything else which uses rust).
          # Instead, we just want to update the scope that crane will use by
          # appending our specific toolchain there.
          craneLib = (crane.mkLib pkgs).overrideToolchain rust;
          # craneLib = crane.lib."${system}";

          ic-repl = craneLib.buildPackage {
            src = ic-repl-src;
            nativeBuildInputs = [
              pkgs.libiconv

              # https://nixos.wiki/wiki/Rust#Building_the_openssl-sys_crate
              pkgs.openssl_1_1
              pkgs.pkgconfig
            ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.Security
            ];
          };

          ic-wasm = craneLib.buildPackage {
            src = pkgs.stdenv.mkDerivation {
              name = "ic-wasm-src";
              src = pkgs.fetchFromGitHub {
                owner = "dfinity";
                repo = "ic-wasm";
                rev = "2e876e84953e24e6a1820aa524f228c8edea4307";
                sha256 = "sha256-0E7Qa0tOtFwV6pkZsjvkGE2TGaj/30+JSlNGtiU0xYo=";
              };
              installPhase = ''
                cp -R --preserve=mode,timestamps . $out
              '';
            };
            doCheck = false;
            nativeBuildInputs = [
              pkgs.libiconv
            ];
          };
        in
        {
          checks = {
            # inherit ;
          };

          packages = {
            # inherit ;
          };

          # defaultPackage = ;

          devShell = pkgs.mkShell {
            inputsFrom = builtins.attrValues self.checks;
            nativeBuildInputs = with pkgs; [
              dfinitySdk
              swift
            ];
          };
        });
}
