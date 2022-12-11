{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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

          cdk-swift-build = pkgs.writeShellApplication {
            name = "cdk-swift-build";
            runtimeInputs = [
              ic-wasm
              swift-wasm
              wasm-snip-wasi
            ];
            text = ''
              BUILD_DIR=.build/wasm32-unknown-wasi/release
              swift-wasm build -c release
              wasm-snip-wasi "$BUILD_DIR/$1.wasm" --output "$BUILD_DIR/$1-snipped.wasm"
              ic-wasm --output "$BUILD_DIR/$1-snipped-shrunk.wasm" "$BUILD_DIR/$1-snipped.wasm" shrink
              wasm2wat "$BUILD_DIR/$1-snipped-shrunk.wasm" --output "$BUILD_DIR/$1-snipped-shrunk.wat"
              gzip --to-stdout --best "$BUILD_DIR/$1-snipped-shrunk.wasm" > "$BUILD_DIR/$1.wasm.gz"
            '';
          };

          cdk-swift-test = pkgs.writeShellApplication {
            name = "cdk-swift-test";
            runtimeInputs = [
              dfinitySdk
            ];
            text = ''
              set -e

              HOME=$TMPDIR

              trap "EXIT_CODE=\$? dfx stop && exit \$EXIT_CODE" EXIT

              dfx start --background --host 127.0.0.1:0
              WEBSERVER_PORT=$(dfx info webserver-port)

              dfx deploy --network "http://127.0.0.1:$WEBSERVER_PORT" --no-wallet API_backend

              dfx stop
            '';
          };

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

          swift-wasm = pkgs.writeShellApplication {
            name = "swift-wasm";
            runtimeInputs = [];
            text = ''
              swift "$@" --triple wasm32-unknown-wasi
            '';
          };

          wasm-snip = craneLib.buildPackage {
            src = pkgs.stdenv.mkDerivation {
              name = "wasm-snip-src";
              src = pkgs.fetchCrate {
                pname = "wasm-snip";
                version = "0.4.0";
                sha256 = "sha256-+oThqcy3H4/s2T+Uw0V/nnVzx7SW5xPghbaJxoub7yc=";
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

          # wasm-snip-wasi input.wasm --output output.wasm
          wasm-snip-wasi = pkgs.runCommand "wasm-snip-wasi" {
            buildInputs = [
              pkgs.makeWrapper
            ];
          } ''
              makeWrapper ${wasm-snip}/bin/wasm-snip $out/bin/wasm-snip-wasi \
                --append-flags "\
                  __imported_wasi_snapshot_preview1_args_get \
                  __imported_wasi_snapshot_preview1_args_sizes_get \
                  __imported_wasi_snapshot_preview1_clock_res_get \
                  __imported_wasi_snapshot_preview1_clock_time_get \
                  __imported_wasi_snapshot_preview1_environ_get \
                  __imported_wasi_snapshot_preview1_environ_sizes_get \
                  __imported_wasi_snapshot_preview1_fd_advise \
                  __imported_wasi_snapshot_preview1_fd_allocate \
                  __imported_wasi_snapshot_preview1_fd_close \
                  __imported_wasi_snapshot_preview1_fd_datasync \
                  __imported_wasi_snapshot_preview1_fd_fdstat_get \
                  __imported_wasi_snapshot_preview1_fd_fdstat_set_flags \
                  __imported_wasi_snapshot_preview1_fd_fdstat_set_rights \
                  __imported_wasi_snapshot_preview1_fd_filestat_get \
                  __imported_wasi_snapshot_preview1_fd_filestat_set_size \
                  __imported_wasi_snapshot_preview1_fd_filestat_set_times \
                  __imported_wasi_snapshot_preview1_fd_pread \
                  __imported_wasi_snapshot_preview1_fd_prestat_dir_name \
                  __imported_wasi_snapshot_preview1_fd_prestat_get \
                  __imported_wasi_snapshot_preview1_fd_pwrite \
                  __imported_wasi_snapshot_preview1_fd_read \
                  __imported_wasi_snapshot_preview1_fd_readdir \
                  __imported_wasi_snapshot_preview1_fd_renumber \
                  __imported_wasi_snapshot_preview1_fd_seek \
                  __imported_wasi_snapshot_preview1_fd_sync \
                  __imported_wasi_snapshot_preview1_fd_tell \
                  __imported_wasi_snapshot_preview1_fd_write \
                  __imported_wasi_snapshot_preview1_path_create_directory \
                  __imported_wasi_snapshot_preview1_path_filestat_get \
                  __imported_wasi_snapshot_preview1_path_filestat_set_times \
                  __imported_wasi_snapshot_preview1_path_link \
                  __imported_wasi_snapshot_preview1_path_open \
                  __imported_wasi_snapshot_preview1_path_readlink \
                  __imported_wasi_snapshot_preview1_path_remove_directory \
                  __imported_wasi_snapshot_preview1_path_rename \
                  __imported_wasi_snapshot_preview1_path_symlink \
                  __imported_wasi_snapshot_preview1_path_unlink_file \
                  __imported_wasi_snapshot_preview1_poll_oneoff \
                  __imported_wasi_snapshot_preview1_proc_exit \
                  __imported_wasi_snapshot_preview1_proc_raise \
                  __imported_wasi_snapshot_preview1_random_get \
                  __imported_wasi_snapshot_preview1_sched_yield \
                  __imported_wasi_snapshot_preview1_sock_recv \
                  __imported_wasi_snapshot_preview1_sock_send \
                  __imported_wasi_snapshot_preview1_sock_shutdown \
                "
          '';
        in
          {
            checks = {
              # inherit ;
            };

            apps = {
              # inherit ;
            };

            packages = {
              # inherit ;
            };

            # defaultPackage = ;

            devShell = pkgs.mkShell {
              inputsFrom = builtins.attrValues self.checks;
              nativeBuildInputs = [
                cdk-swift-build
                cdk-swift-test
                dfinitySdk
                ic-wasm
                pkgs.wabt
                swift-wasm
                wasm-snip-wasi
              ];
              shellHook = ''
                export PATH=/Library/Developer/Toolchains/swift-wasm-5.6.0-RELEASE.xctoolchain/usr/bin:"$PATH";
              '';
            };
          }
      );
}
