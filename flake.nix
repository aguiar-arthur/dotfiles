{
  description = "aguiar - Cross-platform Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      
      # Helper function to generate config for each system
      mkHomeConfiguration = system: 
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            {
              # Basic home-manager configuration
              home.username = "your-username";  # Replace with your actual username
              home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/your-username" else "/home/your-username";
              home.stateVersion = "23.11";
              
              # Let Home Manager install and manage itself
              programs.home-manager.enable = true;

              # Cross-platform packages
              home.packages = with pkgs; [
                # Editors
                emacs
                vim
                
                # Development tools
                git
                curl
                wget
                tree
                htop
                
                # Programming languages
                python3
                
                # Utilities
                ripgrep
                fd
                bat
                exa
                fzf
                jq
                coreutils
                findutils
                
                # Fonts
                (nerdfonts.override { fonts = [ "FiraCode" ]; })
                
                # Terminal tools
                tmux
                zsh
                neofetch
                alacritty
                
              ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
                # macOS-specific packages
                # Add any macOS-only packages here
                
              ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
                # Linux-specific packages
                firefox
                xournalpp
                # Add any Linux-only packages here
              ];

              # Configure programs declaratively
              programs = {
                # Git configuration
                git = {
                  enable = true;
                  extraConfig = {
                    init.defaultBranch = "main";
                    pull.rebase = true;
                  };
                };
                
                # Zsh configuration with Oh My Zsh
                zsh = {
                  enable = true;
                  enableCompletion = true;
                  enableAutosuggestions = true;
                  syntaxHighlighting.enable = true;
                  
                  oh-my-zsh = {
                    enable = true;
                    plugins = [ "git" "sudo" ];
                    theme = "agnoster";
                  };
                  
                  shellAliases = {
                    ll = "exa -la";
                    la = "exa -a";
                    ls = "exa";
                    cat = "bat";
                    grep = "ripgrep";
                  };
                };
                
                # Tmux configuration
                tmux = {
                  enable = true;
                  clock24 = true;
                  keyMode = "emacs";
                };
              };

              # Environment variables
              home.sessionVariables = {
                EDITOR = "vim";
                BROWSER = if pkgs.stdenv.isLinux then "firefox" else "open";
              };

              # Platform-specific configurations
              home.file = pkgs.lib.mkMerge [
                # macOS-specific files
                (pkgs.lib.mkIf pkgs.stdenv.isDarwin {
                  # Add macOS-specific dotfiles here
                })
                
                # Linux-specific files  
                (pkgs.lib.mkIf pkgs.stdenv.isLinux {
                  # Add Linux-specific dotfiles here
                })
              ];
            }
          ];
        };
    in {
      homeConfigurations = {
        # Multi-platform support
        "aguiar-x86_64-linux" = mkHomeConfiguration "x86_64-linux";
        "aguiar-aarch64-darwin" = mkHomeConfiguration "aarch64-darwin";
        
        # Default "aguiar" auto-detects system
        "aguiar" = mkHomeConfiguration (builtins.currentSystem or "x86_64-linux");
      };
    };
}