{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  flutter,
  makeDesktopItem,
  pkg-config,
  libayatana-appindicator,
  undmg,
  makeBinaryWrapper,
}:

let
  pname = "picguard";
  version = "1.0.0+404";

  linux = flutter.buildFlutterApplication rec {
    inherit pname version;

    src = fetchFromGitHub {
      owner = pname;
      repo = pname;
      rev = "v${version}";
      hash = "sha256-rs+0E5/CFyWjA4u2hWk8NkHXfrWUd5T8UOGn4hUwUnc=";
    };

    sourceRoot = "${src.name}";

    pubspecLock = lib.importJSON ./pubspec.lock.json;

    gitHashes = {
      "app_settings" = "sha256-HTAlSxstdXsS7jJN/3F/A2UPDcLJMzzDN48fi2sv4ZQ=";
    };

    nativeBuildInputs = [ pkg-config ];

    buildInputs = [ libayatana-appindicator ];

    postInstall = ''
      for s in 32 128 256 512; do
        d=$out/share/icons/hicolor/''${s}x''${s}/apps
        mkdir -p $d
        ln -s $out/app/data/flutter_assets/logo/logo-''${s}.png $d/picguard.png
      done
      mkdir -p $out/share/applications
      cp $desktopItem/share/applications/*.desktop $out/share/applications
      substituteInPlace $out/share/applications/*.desktop --subst-var out
    '';

    desktopItem = makeDesktopItem {
      name = "PicGuard";
      exec = "@out@/bin/picguard";
      icon = "picguard";
      desktopName = "PicGuard";
      startupWMClass = "picguard";
      genericName = "Your pictures, your signature";
      categories = [ "Utility" ];
    };

    passthru = {
      updateScript = ./update.sh;
    };

    meta = metaCommon // {
      mainProgram = "picguard";
    };
  };

  darwin = stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/picguard/picguard/releases/download/v${version}/PicGuard_${version}_macos_universal.dmg";
      hash = "sha256-SF74LUkIw35Ij0b/O0iJsDvCO2whx4ufQ6sWMIptbJc=";
    };

    nativeBuildInputs = [
      undmg
      makeBinaryWrapper
    ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/Applications
      cp -r *.app $out/Applications
      makeBinaryWrapper $out/Applications/PicGuard.app/Contents/MacOS/PicGuard $out/bin/picguard
    '';

    meta = metaCommon // {
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      platforms = [
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  };

  metaCommon = {
    description = "Your pictures, your signature";
    homepage = "https://picguard.app/";
    license = lib.licenses.mit;
    mainProgram = "picguard";
    maintainers = with lib.maintainers; [
      kjxbyz
    ];
  };
in
if stdenv.isDarwin then darwin else linux
