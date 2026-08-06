{
  pkgs,
  config,
}: let
  mkPackageArray = packages:
    builtins.concatStringsSep "\n" (map (pkg: "        " + pkgs.lib.escapeShellArg pkg) packages);

  mkGlobalInstall = {
    packages,
    postinstallPackages ? [],
  }:
    config.lib.dag.entryAfter ["writeBoundary"] ''
            export PNPM_HOME="$HOME/.local/share/pnpm"
            export PATH="${pkgs.pnpm}/bin:${pkgs.nodejs}/bin:$PNPM_HOME/bin:$PNPM_HOME:$PATH"
            state_file="$PNPM_HOME/.hm-global-packages"

            mkdir -p "$PNPM_HOME"

            desired_packages=(
      ${mkPackageArray packages}
            )

            postinstall_packages=(
      ${mkPackageArray postinstallPackages}
            )

            if [ -f "$state_file" ]; then
              while IFS= read -r pkg; do
                [ -z "$pkg" ] && continue

                should_keep=false
                for desired in "''${desired_packages[@]}"; do
                  if [ "$desired" = "$pkg" ]; then
                    should_keep=true
                    break
                  fi
                done

                if [ "$should_keep" = false ]; then
                  pnpm remove -g "$pkg" >/dev/null 2>&1 || true
                fi
              done < "$state_file"
            fi

            if [ "''${#desired_packages[@]}" -gt 0 ]; then
              pnpm add -g "''${desired_packages[@]}"
              pnpm update -g --latest "''${desired_packages[@]}"
            fi

            if [ "''${#postinstall_packages[@]}" -gt 0 ]; then
              for pkg in "''${postinstall_packages[@]}"; do
                package_dir="$(
                  pnpm list -g --depth=-1 --json \
                    | ${pkgs.jq}/bin/jq -r --arg pkg "$pkg" '.[0].dependencies[$pkg].path // empty'
                )"
                postinstall_script="$package_dir/postinstall.mjs"

                if [ ! -f "$postinstall_script" ]; then
                  printf "Expected postinstall script not found: %s\n" "$postinstall_script" >&2
                  exit 1
                fi

                (cd "$package_dir" && node postinstall.mjs)
              done
            fi

            : > "$state_file"
            for pkg in "''${desired_packages[@]}"; do
              printf "%s\n" "$pkg" >> "$state_file"
            done
    '';
in {
  inherit mkGlobalInstall;
}
