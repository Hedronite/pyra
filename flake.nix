{
  description = "Pyra (formerly python-gate): closed-world Python. Nix is the gate, uv owns the expression";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      # nixos-unstable (26.11+) dropped x86_64-darwin. Intel Macs: stay on
      # `uv sync` (Level 1) or pin nixpkgs-26.05-darwin.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs systems;

      # Rename this when you clone the template, along with [project] name,
      # [project.scripts], src/<module>/, and tool.uv.build-backend.module-name.
      # `python-gate` / `python_gate` are compatibility aliases for the old name.
      projectName = "pyra";

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      overlay = workspace.mkPyprojectOverlay {
        # Wheels "just work" more often than sdists. Per-package overrides still win.
        sourcePreference = "wheel";
      };

      # Same Python set for packages.default and (editable overlay on top) devShells.default.
      pythonSets = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python3;
        in
        (pkgs.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope
          (
            lib.composeManyExtensions [
              pyproject-build-systems.overlays.wheel
              overlay
            ]
          )
      );
    in
    {
      # `nix flake new -t github:Hedronite/pyra`
      # Output name is `default`.
      templates.default = {
        path = ./.;
        description = "Pyra (formerly python-gate): closed-world Python. Nix is the gate, uv owns the expression";
        welcomeText = ''
          # Pyra

          Formerly python-gate.
          Nix is the gate. uv owns the expression. `nix run` is the product.

          - Non-Nix: `uv sync` then `uv run pyra`
            (`uv run python-gate` is the same script)
          - Nix / CI: `nix develop` and `nix run .#`

          This template is Level 3 (pure Python). Level 4 is a direction,
          not a feature of this tree.
          Commit both lockfiles. A lockfile is not a closure.
          See README.md for the ladder, the peace treaty, and agent grading.
        '';
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pythonSet = pythonSets.${system};
          inherit (pkgs.callPackages pyproject-nix.build.util { }) mkApplication;
        in
        {
          # mkVirtualEnv builds the world; mkApplication locks the door.
          default = mkApplication {
            venv = pythonSet.mkVirtualEnv "${projectName}-env" workspace.deps.default;
            package = pythonSet.${projectName};
          };
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/${projectName}";
        };
        # Former name. Same product as `default`.
        python-gate = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/python-gate";
        };
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pythonSet = pythonSets.${system}.overrideScope (
            workspace.mkEditablePyprojectOverlay { root = "$REPO_ROOT"; }
          );
          virtualenv = pythonSet.mkVirtualEnv "${projectName}-dev-env" workspace.deps.all;
        in
        {
          default = pkgs.mkShell {
            packages = [
              virtualenv
              pkgs.uv
              pkgs.git
            ];

            # Peace treaty: Nix owns the interpreter and the world.
            # uv may rewrite uv.lock; it must not invent a second venv.
            env = {
              UV_NO_SYNC = "1";
              UV_PYTHON = pythonSet.python.interpreter;
              UV_PYTHON_DOWNLOADS = "never";
            };

            shellHook = ''
              unset PYTHONPATH
              export REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
            '';
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          app = self.packages.${system}.default;
          pyraRuns = pkgs.runCommand "pyra-runs" { } ''
            ${app}/bin/pyra > $out
            # Compat script. Same entry point as pyra.
            ${app}/bin/python-gate > /dev/null
          '';
        in
        {
          pyra-runs = pyraRuns;
          # Former check attribute. Same derivation as pyra-runs.
          python-gate-runs = pyraRuns;
        }
      );
    };
}
