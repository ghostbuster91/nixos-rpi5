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
