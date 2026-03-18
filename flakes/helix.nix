{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    devShells = nixpkgs.lib.genAttrs systems (
      system: let
        pkgs = import nixpkgs {inherit system;};

        helixConfig = pkgs.writeText "helix-config.toml" ''
          [editor]
          line-number = "relative"
          cursorline = true
          auto-save = true
          true-color = true

          [editor.lsp]
          display-messages = true

          [keys.normal]
          C-s = ":write"
          C-p = "file_picker"
          A-p = "file_picker"
          C-a = "goto_line_start"
          C-e = "goto_line_end"
          K = "hover"

          [keys.normal.g]
          d = "goto_definition"
          r = "goto_reference"

          [keys.normal."["]
          d = "goto_prev_diag"

          [keys.normal."]"]
          d = "goto_next_diag"

          [keys.normal.space]
          w = ":write"
          "/" = "toggle_comments"

          [keys.normal.space.q]
          q = ":quit!"
          w = ":wq"

          [keys.normal.space.c]
          d = "goto_definition"
          a = "code_action"
          r = "rename_symbol"
          R = "goto_reference"
          f = "format_selections"

          [keys.normal.space.d]
          d = "diagnostics_picker"

          [keys.normal.space.s]
          a = "global_search"
          c = "search_selection"
          s = "file_picker"
          t = "symbol_picker"

          [keys.normal.space.g]
          s = ":sh git status --short"
          d = ":sh git diff"
          p = ":sh git diff -- %"
          h = ":sh git log --oneline -- %"

          [keys.normal.space.l]
          e = ":reload"
          E = ":reload"
          a = ":reload-all"

          [keys.insert]
          C-s = ":write"
          C-a = "goto_line_start"
          C-e = "goto_line_end"
          A-b = "move_prev_word_start"
          A-f = "move_next_word_start"
        '';

        helixLanguages = pkgs.writeText "helix-languages.toml" ''
          [[language]]
          name = "nix"
          scope = "source.nix"
          file-types = ["nix"]
          auto-format = true
          formatter = { command = "alejandra" }

          [[language]]
          name = "typescript"
          scope = "source.ts"
          file-types = ["ts", "mts", "cts"]
          auto-format = true
          formatter = { command = "prettierd" }

          [[language]]
          name = "javascript"
          scope = "source.js"
          file-types = ["js", "mjs", "cjs"]
          auto-format = true
          formatter = { command = "prettierd" }

          [[language]]
          name = "json"
          scope = "source.json"
          file-types = ["json", "jsonc"]
          auto-format = true
          formatter = { command = "prettierd" }

          [[language]]
          name = "yaml"
          scope = "source.yaml"
          file-types = ["yaml", "yml"]
          auto-format = true
          formatter = { command = "prettierd" }

          [[language]]
          name = "markdown"
          scope = "source.md"
          file-types = ["md", "markdown"]
          auto-format = true
          formatter = { command = "prettierd" }
        '';

        hxw = pkgs.writeShellApplication {
          name = "hxw";
          runtimeInputs = with pkgs; [
            helix
            git
            ripgrep
            fd
          ];
          text = ''
            set -euo pipefail

            cfg_root="$(mktemp -d)"
            trap 'rm -rf "$cfg_root"' EXIT

            mkdir -p "$cfg_root/helix"
            ln -sf ${helixConfig} "$cfg_root/helix/config.toml"
            ln -sf ${helixLanguages} "$cfg_root/helix/languages.toml"

            export XDG_CONFIG_HOME="$cfg_root"
            exec ${pkgs.helix}/bin/hx "$@"
          '';
        };
      in {
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.helix
            pkgs.alejandra
            pkgs.prettierd
            pkgs.beautysh
            pkgs.git
            pkgs.ripgrep
            pkgs.fd
            hxw
          ];

          shellHook = ''
            echo "Helix wrapper available: hxw"
          '';
        };
      }
    );
  };
}
