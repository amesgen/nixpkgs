{ lib, stdenv
, pkg-config
, glib
, libxml2
, expat
, fftw
, orc
, lcms
, imagemagick
, openexr
, libtiff
, libjpeg
, libgsf
, libexif
, libheif
, librsvg
, ApplicationServices
, Foundation
, python27
, libpng
, fetchFromGitHub
, fetchpatch
, autoreconfHook
, gtk-doc
, gobject-introspection
,
}:

stdenv.mkDerivation rec {
  pname = "vips";
  version = "8.11.2";

  outputs = [ "bin" "out" "man" "dev" ];

  src = fetchFromGitHub {
    owner = "libvips";
    repo = "libvips";
    rev = "v${version}";
    sha256 = "sha256-Psb+LrpTWtZwO9ekOLJIXsy8W49jW4Jdi+EmiJ+1MsQ=";
    # Remove unicode file names which leads to different checksums on HFS+
    # vs. other filesystems because of unicode normalisation.
    extraPostFetch = ''
      rm -r $out/test/test-suite/images/
    '';
  };

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
    gtk-doc
    gobject-introspection
  ];

  buildInputs = [
    glib
    libxml2
    fftw
    orc
    lcms
    imagemagick
    openexr
    libtiff
    libjpeg
    libgsf
    libexif
    libheif
    libpng
    librsvg
    python27
    libpng
    expat
  ] ++ lib.optionals stdenv.isDarwin [ApplicationServices Foundation];

  # Required by .pc file
  propagatedBuildInputs = [
    glib
  ];

  autoreconfPhase = ''
    NOCONFIGURE=1 ./autogen.sh
  '';

  meta = with lib; {
    homepage = "https://libvips.github.io/libvips/";
    description = "Image processing system for large images";
    license = licenses.lgpl2Plus;
    maintainers = with maintainers; [ kovirobi ];
    platforms = platforms.unix;
  };
}
