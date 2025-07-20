{
  description = "Malina 5";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    deploy-rs.url = "github:serokell/deploy-rs";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    devshell.url = "github:numtide/devshell";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-linux" "x86_64-linux" ];
      imports = [
        ./machines
        ./nix
        inputs.devshell.flakeModule
      ];
    };
  # outputs = inputs @ { self, nixpkgs, nixos-raspberrypi, ... }:
  #   {
  #     nixosConfigurations = {
  #       malina5 = nixos-raspberrypi.lib.nixosSystemFull  {
  #         specialArgs = inputs;
  #         system = "aarch64-linux";
  #         modules = [
  #           nixos-raspberrypi.nixosModules.raspberry-pi-5.base
  #           nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
  #           nixos-raspberrypi.nixosModules.raspberry-pi-5.bluetooth
  #           ./configuration.nix
  #           ./monitoring.nix
  #           ./pi5-config.nix
  #         ];
  #       };
  #     };
  #     deploy = {
  #       nodes = {
  #         malina5 = {
  #           sshUser = "kghost";
  #           hostname = "malina5.local";
  #           user = "root";
  #           remoteBuild = true;
  #           sshOpts = [ "-oControlMaster=no" ];
  #           profiles.system.path =
  #             inputs.deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.malina5;
  #         };
  #       };
  #
  #     };
  #   };
  nixConfig = {
    extra-substituters = [ 
        "https://nix-community.cachix.org" 
        "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };
}
