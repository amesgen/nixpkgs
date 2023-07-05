{ stdenv
, buildPackages
, fetchFromGitHub
, lib
, firefox-unwrapped
, firefox-esr-unwrapped
, pkgsCross
, wasmtime
}:

let
  pname = "wasilibc";
  version = "21";
in
stdenv.mkDerivation {
  inherit pname version;

  src = buildPackages.fetchFromGitHub {
    owner = "WebAssembly";
    repo = "wasi-libc";
    rev = "refs/tags/wasi-sdk-${version}";
    hash = "sha256-1LsMpO29y79twVrUsuM/JvC7hK8O6Yey4Ard/S3Mvvc=";
    fetchSubmodules = true;
  };

  outputs = [ "out" "dev" "share" ];

  # clang-13: error: argument unused during compilation: '-rtlib=compiler-rt' [-Werror,-Wunused-command-line-argument]
  postPatch = ''
    substituteInPlace Makefile \
      --replace "-Werror" ""
  '';

  preBuild = ''
    export SYSROOT_LIB=${builtins.placeholder "out"}/lib
    export SYSROOT_INC=${builtins.placeholder "dev"}/include
    export SYSROOT_SHARE=${builtins.placeholder "share"}/share
    mkdir -p "$SYSROOT_LIB" "$SYSROOT_INC" "$SYSROOT_SHARE"
    makeFlagsArray+=(
      "SYSROOT_LIB:=$SYSROOT_LIB"
      "SYSROOT_INC:=$SYSROOT_INC"
      "SYSROOT_SHARE:=$SYSROOT_SHARE"
      # https://bugzilla.mozilla.org/show_bug.cgi?id=1773200
      "BULK_MEMORY_SOURCES:="
    )

  '';

  enableParallelBuilding = true;

  # We just build right into the install paths, per the `preBuild`.
  dontInstall = true;

  preFixup = ''
    ln -s $share/share/undefined-symbols.txt $out/lib/wasi.imports
  '';

  passthru.tests = {
    inherit firefox-unwrapped firefox-esr-unwrapped;
    simple-c-cxx-binaries = pkgsCross.wasi32.runCommandCC "simple-c-cxx-binaries"
      {
        nativeBuildInputs = [
          wasmtime
        ];
      } ''
      cat > test.c <<EOF
      #include <stdio.h>
      int main(void) {
        puts("Hello from C");
        return 0;
      }
      EOF
      cat > test.cpp <<EOF
      #include <iostream>
      int main(void) {
        std::cout<<"Hello from C++\n";
        return 0;
      }
      EOF

      mkdir -p "$out/bin"
      # TODO(@sternenseemann): compile with -pthread if enableThreads
      $CC -o "$out/bin/test-c" test.c
      $CXX -o "$out/bin/test-cxx" test.cpp -lc++ -lc++abi

      export HOME=$TMPDIR
      wasmtime run "''${WASMTIME_FLAGS[@]}" "$out/bin/test-c"
      wasmtime run "''${WASMTIME_FLAGS[@]}" "$out/bin/test-cxx"
    '';
  };

  meta = with lib; {
    changelog = "https://github.com/WebAssembly/wasi-sdk/releases/tag/wasi-sdk-${version}";
    description = "WASI libc implementation for WebAssembly";
    homepage = "https://wasi.dev";
    platforms = platforms.wasi;
    maintainers = with maintainers; [ matthewbauer rvolosatovs ];
    license = with licenses; [ asl20-llvm mit ];
  };
}
