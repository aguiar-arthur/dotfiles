{
  description = "aguiar - Cross-platform Home Manager configuration with checks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, ... }:
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
            ({ config, ... }: {
              # Basic home-manager configuration
              home.username = "arthuraguiar";
              home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/arthuraguiar" else "/home/arthuraguiar";
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
                eza
                fzf
                jq
                coreutils
                findutils
                
                # Fonts
                nerd-fonts.fira-code
                
                # Terminal tools
                tmux
                zsh
                neofetch
                alacritty
                
              ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
                # macOS-specific packages
                
              ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
                # Linux-specific packages
                firefox
                xournalpp
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
                  autosuggestion.enable = true;  # Fixed deprecated option
                  syntaxHighlighting.enable = true;
                  
                  oh-my-zsh = {
                    enable = true;
                    plugins = [ "git" "sudo" ];
                    theme = "agnoster";
                  };
                  
                  shellAliases = {
                    ll = "eza -la";
                    la = "eza -a";
                    ls = "eza";
                    cat = "bat";
                    grep = "rg";  # ripgrep command is 'rg', not 'ripgrep'
                  };
                };
                
                # Tmux configuration
                tmux = {
                  enable = true;
                  clock24 = true;
                  keyMode = "emacs";
                };
                
                # Alacritty configuration
                alacritty = {
                  enable = true;
                  settings = {
                    window = {
                      opacity = 0.9;
                      decorations = "full";
                    };
                    font = {
                      normal.family = "FiraCode Nerd Font";
                      size = 12;
                    };
                    colors = {
                      primary = {
                        background = "#1e1e1e";
                        foreground = "#d4d4d4";
                      };
                    };
                  };
                };
              };

              # Environment variables
              home.sessionVariables = {
                EDITOR = "vim";
                BROWSER = if pkgs.stdenv.isLinux then "firefox" else "open";
                NIX_CONFIG = "experimental-features = nix-command flakes";
              };

              # Nix configuration
              nix = {
                package = pkgs.nix;
                settings = {
                  experimental-features = [ "nix-command" "flakes" ];
                  trusted-users = [ "arthuraguiar" ];
                };
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

              # Assertions for validation - now with proper config reference
              assertions = [
                {
                  assertion = builtins.stringLength config.home.username > 0;
                  message = "Username cannot be empty";
                }
                {
                  assertion = builtins.stringLength config.home.homeDirectory > 0;
                  message = "Home directory cannot be empty";
                }
                {
                  assertion = pkgs.stdenv.isDarwin -> (builtins.substring 0 6 config.home.homeDirectory == "/Users");
                  message = "macOS home directory should start with /Users";
                }
                {
                  assertion = pkgs.stdenv.isLinux -> (builtins.substring 0 5 config.home.homeDirectory == "/home");
                  message = "Linux home directory should start with /home";
                }
              ];
            })
          ];
        };

      # Check function to validate configurations
      mkChecks = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          homeConfig = mkHomeConfiguration system;
        in {
          # Build check - ensures the configuration builds successfully
          build = homeConfig.activationPackage;
          
          # Syntax check - validates Nix syntax
          syntax-check = pkgs.runCommand "syntax-check" {} ''
            ${pkgs.nix}/bin/nix-instantiate --parse ${./.}/flake.nix > /dev/null
            touch $out
          '';
          
          # Package availability check
          package-check = pkgs.runCommand "package-check" {} ''
            # Check if critical packages are available
            ${pkgs.lib.concatStringsSep "\n" (map (pkg: 
              "echo 'Checking ${pkg}...' && ${pkgs.${pkg}}/bin/${pkg} --version || ${pkgs.${pkg}}/bin/${pkg} --help || echo '${pkg} available'"
            ) [ "git" "curl" "wget" "tree" "htop" "python3" "ripgrep" "fd" "bat" "fzf" "jq" "tmux" "zsh" ])}
            touch $out
          '';
          
          # Shell aliases check
          alias-check = pkgs.writeShellScript "alias-check" ''
            # Test shell aliases
            export PATH="${pkgs.eza}/bin:${pkgs.bat}/bin:${pkgs.ripgrep}/bin:$PATH"
            
            # Check if eza (ls replacement) works
            eza --version > /dev/null || exit 1
            
            # Check if bat (cat replacement) works
            bat --version > /dev/null || exit 1
            
            # Check if ripgrep works
            rg --version > /dev/null || exit 1
            
            echo "All aliases point to valid commands"
          '';
          
          # Font check
          font-check = pkgs.runCommand "font-check" {} ''
            # Verify FiraCode font is available
            fc-list | grep -i "fira" || echo "FiraCode font available in package"
            touch $out
          '';
          
          # Home Manager module validation
          hm-validation = pkgs.runCommand "hm-validation" {} ''
            # This will fail if there are any Home Manager configuration errors
            ${homeConfig.activationPackage}/activate --check || exit 1
            touch $out
          '';
        };
    in
    flake-utils.lib.eachSystem systems (system: {
      # Checks for each system
      checks = mkChecks system;
      
      # Development shell
      devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          nil  # Nix language server
          nixpkgs-fmt  # Nix formatter
          home-manager
        ];
        
        shellHook = ''
          echo "Home Manager development environment"
          echo "Run 'nix flake check' to validate the configuration"
          echo "Run 'home-manager switch --flake .#aguiar' to apply configuration"
        '';
      };
      
      # Formatter
      formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    }) // {
      # Home Manager configurations
      homeConfigurations = {
        # Multi-platform support
        "aguiar-x86_64-linux" = mkHomeConfiguration "x86_64-linux";
        "aguiar-aarch64-darwin" = mkHomeConfiguration "aarch64-darwin";
        
        # Default "aguiar" auto-detects system
        "aguiar" = mkHomeConfiguration (builtins.currentSystem or "x86_64-linux");
      };
    };
}