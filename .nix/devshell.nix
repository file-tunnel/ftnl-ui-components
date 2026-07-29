{ pkgs, agentCheck }:
pkgs.mkShell {
  packages = [
    agentCheck
  ]
  ++ (with pkgs; [
    actionlint
    flutter
    git
    gradle_9
    jdk21
    jq
    nixfmt
    nodejs_22
    ripgrep
    shellcheck
    shfmt
  ]);

  JAVA_HOME = pkgs.jdk21.home;
  LANG = if pkgs.stdenv.hostPlatform.isDarwin then "en_US.UTF-8" else "C.UTF-8";
  LC_ALL = if pkgs.stdenv.hostPlatform.isDarwin then "en_US.UTF-8" else "C.UTF-8";

  shellHook = ''
    export FTNL_DEV_SHELL="ui-components"
    export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$PWD/.cache/nix-agent}"
    export GRADLE_USER_HOME="''${GRADLE_USER_HOME:-$PWD/.cache/nix-agent/gradle}"
  '';
}
