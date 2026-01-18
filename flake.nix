{
  nixConfig = {
    bash-prompt = "\[nixos-raspberrypi-demo\] ➜ ";
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
    connect-timeout = 5;
  };

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixos-raspberrypi
    , disko
    , nixos-anywhere
    , ...
    }@inputs:
    let
      allSystems = nixpkgs.lib.systems.flakeExposed;
      forSystems = systems: f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {

      devShells = forSystems allSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              nil # lsp language server for nix
              nixpkgs-fmt
              nix-output-monitor
              nixos-anywhere.packages.${system}.default
            ];
          };
        });

      nixosConfigurations =
        {

          malina5 = nixos-raspberrypi.lib.nixosSystemFull {
            specialArgs = inputs;
            modules = [
              disko.nixosModules.disko
              inputs.impermanence.nixosModules.impermanence
              ./hosts/malina5/hw.nix
              ./hosts/malina5/disko-nvme-zfs.nix
              ./hosts/malina5/zfs.nix
              ./hosts/malina5/impermanence.nix
              ./hosts/malina5/kernel.nix
              ./hosts/malina5/network.nix
              ./hosts/malina5/system-user.nix
              # Further user configuration
              ./hosts/malina5/custom.nix
            ];
          };
        };
    };
}
