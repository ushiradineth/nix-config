# Library

Shared Nix helpers for assembling hosts, configuring services and supporting checks.

| File                                         | Purpose                                                                       |
| -------------------------------------------- | ----------------------------------------------------------------------------- |
| [`default.nix`](default.nix)                 | Exports `mylib`, module discovery and root-relative path helpers.             |
| [`hosts.nix`](hosts.nix)                     | Provides host builders, shared module arguments and Colmena host discovery.   |
| [`nixosSystem.nix`](nixosSystem.nix)         | Assembles NixOS and Home Manager configurations.                              |
| [`macosSystem.nix`](macosSystem.nix)         | Assembles nix-darwin and Home Manager configurations.                         |
| [`colmenaSystem.nix`](colmenaSystem.nix)     | Assembles remote deployment configurations.                                   |
| [`docker-helpers.nix`](docker-helpers.nix)   | Generates Docker networks, container dependencies and database dump services. |
| [`traefik-helpers.nix`](traefik-helpers.nix) | Generates reverse-proxy routes for services.                                  |
| [`pnpm.nix`](pnpm.nix)                       | Generates Home Manager activation steps for global pnpm packages.             |
| [`node-types.nix`](node-types.nix)           | Packages pinned Node TypeScript definitions for shared test use.              |

Host outputs import `hosts.nix`. Other consumers can use helpers exposed through `mylib` or import
individual files directly. Helpers provide configuration; importing them does not apply a system
configuration or run package installation.
