{ lib
, stdenv
, fetchFromGitHub
, applyPatches
, rustPlatform
, pkg-config
, cmake
, installShellFiles
, asciidoctor
, openssl
, libusb1
, AppKit
, openssh
}:

rustPlatform.buildRustPackage rec {
  pname = "radicle-cli";
  version = "0.5.1";

  src = applyPatches {
    src = fetchFromGitHub {
      owner = "radicle-dev";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-VqJYtZsiI2BMB6X26/LnlrCrYimj5awbTfWKmLd82RY=";
    };
    # can be removed on the next release
    patches = [ ./fix-incorrect-cargo-lock.patch ];
  };

  cargoSha256 = "sha256-lbd3aWvX9XqOvuenSvCVHXEZYTtk0caMwDLNeCh9GmQ=";

  nativeBuildInputs = [
    pkg-config
    cmake
    installShellFiles
    asciidoctor
  ];

  buildInputs = [ openssl ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ libusb1 AppKit ];

  postInstall = ''
    for f in $(find . -name '*.adoc'); do
      mf=''${f%.*}
      asciidoctor --doctype manpage --backend manpage $f -o $mf
      installManPage $mf
    done
  '';

  checkInputs = [ openssh ];
  preCheck = ''
    eval $(ssh-agent)
  '';

  meta = {
    description = "Command-line tooling for Radicle, a decentralized code collaboration network";
    homepage = "https://radicle.xyz";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ amesgen ];
    platforms = lib.platforms.unix;
    mainProgram = "rad";
  };
}
