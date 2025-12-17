# SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2024-2025 hyperpolymath
# nafa-app-ambient - Nix Flake Definition (Fallback)
# Primary package management: Guix (see guix.scm)
# This flake provides Nix ecosystem compatibility per RSR guidelines.
{
  description = "NAFA - Journey planning app for neurodiverse adventurers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Development shell with project dependencies
        devShells.default = pkgs.mkShell {
          name = "nafa-app-ambient";

          buildInputs = with pkgs; [
            # Elm frontend
            elmPackages.elm
            elmPackages.elm-format
            elmPackages.elm-test
            elmPackages.elm-review

            # Elixir backend
            elixir_1_17
            erlang_27

            # Build tools
            just
            gnumake

            # Container support
            podman

            # Version control
            git
          ];

          shellHook = ''
            echo "NAFA Development Environment (Nix Fallback)"
            echo "Primary package manager: Guix (see guix.scm)"
            echo ""
            echo "Available commands:"
            echo "  just --list    # Show available tasks"
            echo "  elm make       # Build Elm frontend"
            echo "  mix deps.get   # Install Elixir dependencies"
          '';
        };

        # Package definition
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "nafa-app-ambient";
          version = "0.1.0";

          src = ./.;

          meta = with pkgs.lib; {
            description = "Journey planning app for neurodiverse adventurers";
            homepage = "https://github.com/hyperpolymath/nafa-app-ambient";
            license = with licenses; [ mit agpl3Plus ];
            maintainers = [ ];
            platforms = platforms.all;
          };
        };
      }
    );
}
