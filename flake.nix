{
  description = "ComfyUI - A powerful and modular stable diffusion GUI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = false;
            rocmSupport = system == "aarch64-darwin";
          };
        };

        pythonEnv = pkgs.python312.withPackages (ps: with ps; [
          pip
          virtualenv
          # Add other fixed dependencies here
        ]);

        sd-setup = pkgs.writeShellScriptBin "sd-setup" ''
          pip install -U wheel setuptools
          pip install --upgrade --pre torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/nightly/cpu
          pip install --upgrade mflux
          pip install --upgrade -r requirements.txt
        '';

        sd-launch = pkgs.writeShellScriptBin "sd-launch" ''
          python main.py --listen 0.0.0.0
        '';
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.poetry
            sd-setup
            sd-launch
          ];

          shellHook = ''
            # Create virtual environment if it doesn't exist
            if [ ! -d ".venv" ]; then
              python -m venv .venv
            fi
            source .venv/bin/activate

            echo "ComfyUI development environment ready!"
            echo "Run 'sd-setup' to install dependencies"
            echo "Run 'sd-launch' to start the server"
          '';
        };
      }
    );
}
