{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  fetchYarnDeps,
  cargo-tauri,
  glib-networking,
  nodejs,
  yarnConfigHook,
  yarnBuildHook,
  yarnInstallHook,
  openssl,
  pkg-config,
  webkitgtk_4_1,
  wrapGAppsHook4,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {

  pname = "nexterm-connector";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "gnmyt";
    repo = "Nexterm";
    tag = "v${finalAttrs.version}-BETA";
    hash = "sha256-5or9vRC20KDfBjyqiyytav3Ign6yuEb77DvnylrhyMc=";
  };

  client = stdenv.mkDerivation (finalAttrsClient: {
    pname = "${finalAttrs.pname}-client";
    src = "${finalAttrs.src}/client";
    inherit (finalAttrs) version;

    yarnOfflineCache = fetchYarnDeps {
      yarnLock = finalAttrsClient.src + "/yarn.lock";
      hash = "sha256-+QK890ERqR7P3uEm07fHjkqV9Pt+hBlXzOlYSixbyaU=";
    };

    nativeBuildInputs = [
      yarnConfigHook
      yarnBuildHook
      yarnInstallHook
      nodejs
    ];

    postPatch = ''
      substituteInPlace vite.config.js \
        --replace-fail "../vendor/guacamole-client/guacamole-common-js/src/main/webapp/modules" "${finalAttrs.src}/vendor/guacamole-client/guacamole-common-js/src/main/webapp/modules"
    '';

    # Error: spawn /build/source/node_modules/sass-embedded-linux-x64@1.77.8/node_modules/sass-embedded-linux-x64/dart-sass/src/dart ENOENT
    preBuild = ''
      rm -r node_modules/sass-embedded*
    '';

    postBuild = ''
      mv dist/ $out
    '';

  });

  sourceRoot = "${finalAttrs.src.name}/connector";

  postPatch = ''
    substituteInPlace src-tauri/tauri.conf.json \
      --replace-fail "../../client/dist" "${finalAttrs.client}" \
      --replace-fail "yarn client:dev" "" \
      --replace-fail "yarn client:build" ""
  '';

  cargoHash = "sha256-odi7vNtZbH1HfuV78UgaXaaKe7Ko5VXZ6z9kMvKcErY=";

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/connector/yarn.lock";
    hash = "sha256-5+blb6WdEwBnouXDwDuHDF7yzbYGrd0Z4Nywj6jf1Yw=";
  };

  nativeBuildInputs = [
    cargo-tauri.hook

    nodejs
    yarnConfigHook
    yarnBuildHook
    yarnInstallHook

    pkg-config
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ wrapGAppsHook4 ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    glib-networking # Most Tauri apps need networking
    openssl
    webkitgtk_4_1
  ];

  cargoRoot = "src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Open source server management software for SSH, VNC & RDP";
    homepage = "https://nexterm.dev/";
    license = lib.licenses.mit;
    mainProgram = "nexterm-connector";
    maintainers = with lib.maintainers; [
      juliusfreudenberger
    ];
    platforms = lib.platforms.unix;
  };

})
