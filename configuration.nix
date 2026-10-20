{ user, ... }:

{
  # Nix is already installed and manages its own daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  # Manage the Homebrew already installed at /opt/homebrew.
  # nix-homebrew is intentionally omitted because it replaces the existing
  # Homebrew with its pinned brew-src, which is older than the installed one.
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    # Keep the taps that provide sshpass and firstmate-3000@alpha.
    taps = [
      { name = "esolitos/ipa"; trusted = true; }
      { name = "kunchenguid/tap"; trusted = true; }
    ];
    brews = [
      "actionlint"
      "cmake"
      "fd"
      "ffmpeg"
      "fzf"
      "gh"
      "go"
      "herdr"
      "jq"
      "lazygit"
      "neovim"
      "ninja"
      "pnpm"
      "ripgrep"
      "ruff"
      "sevenzip"
      "sshpass"
      "swiftlint"
      "unar"
      "unshield"
      "xcodegen"
      "yt-dlp"
    ];
    casks = [
      "claude-code"
      "font-hack-nerd-font"
      "macshot"
      "opensuperwhisper"
      "wezterm"
    ];
  };
}
