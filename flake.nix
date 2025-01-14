{
  description = "Malina 5";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = inputs @ { self, nixpkgs, raspberry-pi-nix, ... }:
    let
      inherit (nixpkgs.lib) nixosSystem;
    in
    {
      nixosConfigurations = {
        malina5 = nixosSystem {
          system = "aarch64-linux";
          modules = [
            raspberry-pi-nix.nixosModules.raspberry-pi
            raspberry-pi-nix.nixosModules.sd-image
            ./configuration.nix
          ];
        };
      };
      deploy = {
        nodes = {
          malina5 = {
            sshUser = "kghost";
            hostname = "malina5.local";
            user = "root";
            remoteBuild = true;
            sshOpts = [ "-oControlMaster=no" ];
            profiles.system.path =
              inputs.deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.malina5;
          };
        };

      };
    };
  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
