{ inputs, ... }: {
  flake =
    { config
    , lib
    , ...
    }:
    let
      username = "kghost";

      inherit
        (lib)
        filterAttrs
        genAttrs
        mapAttrs
        ;

      # Creates a new nixosSystem with the correct specialArgs, pkgs and name definition
      mkHost = name:
        let
          system = "aarch64-linux";
          pkgs-unstable = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        inputs.nixos-raspberrypi.lib.nixosSystemFull
          {
            specialArgs = {
              inherit (config) nodes;
              inherit inputs username pkgs-unstable;
              inherit (inputs) nixos-raspberrypi;
            };
            modules = [
              ../hosts/${name}
            ];
          };

      # Get all folders in hosts/
      hosts = builtins.attrNames (filterAttrs (_: type: type == "directory") (builtins.readDir ../hosts));
    in
    {
      nixosConfigurations = genAttrs hosts (mkHost);

      # All nixosSystem instanciations are collected here, so that we can refer
      # to any system via nodes.<name>
      nodes = config.nixosConfigurations;
      # Add a shorthand to easily target toplevel derivations
      "@" = mapAttrs (_: v: v.config.system.build.toplevel) config.nodes;
    };
}
