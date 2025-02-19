{
  description = "Rocinante Workstation Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs = inputs@{ self, determinate, nix-darwin, nixpkgs, mac-app-util, nix-homebrew, homebrew-core, homebrew-cask, homebrew-bundle, ... }:
  let
    system = "aarch64-darwin";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    configuration = { config, ... }: {
      environment.systemPackages = with pkgs; [
        vim
        mkalias
        neovim
        tmux
        python311
        python311Packages.pip
        pyenv
        # pyenv dependencies
        openssl
        readline
        sqlite
        zlib
        xz
        tcl-8_6
        tk
        gcc
        libclang
        gnumake
        patch
        # Node.js development
        nodejs
        git
        lazygit
        alacritty
        kitty
        ollama
        slack
        discord
        spotify
        obsidian
        rustup
        kubectl
        go
        tinygo
        lazydocker
        postgresql_17
        # Container and Kubernetes tools
        minikube
        podman
        podman-compose
        qemu    # Required for podman machine
        # Development tools
        pkg-config
        # GUI applications
        google-chrome
        vscode
                
        # Development libraries and tools
        darwin.libiconv
        darwin.apple_sdk.frameworks.Security
        darwin.apple_sdk.frameworks.SystemConfiguration
      ];

      nix.settings.experimental-features = "nix-command flakes";
      programs.zsh = {
        enable = true;
        shellInit = ''
          # pyenv setup
          export PYENV_ROOT="$HOME/.pyenv"
          export PATH="$PYENV_ROOT/bin:$PATH"
          eval "$(pyenv init -)"

          # nvm setup
          export NVM_DIR="$HOME/.nvm"
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
          [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

          # Development environment settings
          export LIBRARY_PATH="${pkgs.darwin.libiconv}/lib"
          export CPPFLAGS="-I${pkgs.darwin.libiconv}/include"
          export LDFLAGS="-L${pkgs.darwin.libiconv}/lib -liconv"
          
          # For pkg-config to find libiconv
          export PKG_CONFIG_PATH="${pkgs.darwin.libiconv}/lib/pkgconfig:${pkgs.openssl.dev}/lib/pkgconfig"
          
          # Ensure rustc can find the libraries
          export RUSTFLAGS="-L ${pkgs.darwin.libiconv}/lib -l iconv"

          # Podman configuration
          export DOCKER_HOST="unix://$HOME/.local/share/containers/podman/machine/podman-machine-default/podman.sock"
          
          # Podman aliases for docker compatibility
          alias docker=podman
          alias docker-compose=podman-compose
        '';
      };
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 5;
      system.defaults = {
        dock.autohide = true;
      };
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;

      nix.extraOptions = ''
        extra-platforms = x86_64-darwin aarch64-darwin
      '';

      homebrew = {
        enable = true;
        brews = [ 
          "mas"
        ];
        casks = [];
        masApps = {
          "NordVPN" = 905953485;
        };
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
        onActivation.cleanup = "zap";
      };
    };
  in
  {
    darwinConfigurations."rocinante" = nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [ 
        configuration
        mac-app-util.darwinModules.default 
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "ahmedt";
            autoMigrate = true;
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
            };
            mutableTaps = true;
          };
        }
      ];
    };
  };
}