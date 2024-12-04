{
  description = "ComfyUI - A powerful and modular stable diffusion GUI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    devShells.aarch64-darwin.default =
      let
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config = {
            allowUnfree = true;
            cudaSupport = false;
            rocmSupport = true;
          };
        };

        python = pkgs.python312;

        sd-launcher = pkgs.writeShellScriptBin "sd-launch" ''
          #!/usr/bin/env bash
          python main.py --listen 0.0.0.0
        '';

        sd-setup = pkgs.writeShellScriptBin "sd-setup" ''
          #!/usr/bin/env bash
          pip install -U wheel setuptools
          pip install --pre torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/nightly/cpu
          pip install -r requirements.txt
        '';
      in pkgs.mkShell {
        buildInputs = with pkgs; [
            sd-launcher
            sd-setup

          # Python environment
          (python.withPackages (ps: with ps; [
            pip
          ]))
        ];

        shellHook = ''
          # Create Python venv if it doesn't exist
          if [ ! -d ".venv" ]; then
          python -m venv .venv
          fi
          source .venv/bin/activate

          echo "ComfyUI development environment ready!"
          '';
        };
  };
}
