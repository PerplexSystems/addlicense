{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, } @ inputs:
    let
      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
      });

      package = pkgs:
        pkgs.buildGoModule {
          pname = "addlicense";
          version = "1.1.2";
          src = ./.;

          vendorHash = "sha256-2mncc21ecpv17Xp8PA9GIodoaCxNBacbbya/shU8T9Y=";

          subPackages = [ "." ];

          meta = with pkgs.lib; {
            description = "Ensures source code files have copyright license headers by scanning directory patterns recursively";
            homepage = "https://github.com/google/addlicense";
            license = licenses.asl20;
            maintainers = with maintainers; [ ratsclub ];
          };
        };
    in
    {
      overlays = {
        default = final: prev: {
          addlicense = package final;
        };
      };

      packages = forAllSystems (system:
        let pkgs = nixpkgsFor."${system}"; in {
          default = package pkgs;
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor."${system}";
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                languages.go.enable = true;
              }
            ];
          };
        });
    };
}
