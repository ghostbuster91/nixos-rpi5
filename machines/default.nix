{ self, inputs, ... }:
{
  flake.nixosConfigurations = {
    malina5 =
        inputs.nixos-raspberrypi.lib.nixosSystemFull  {
          specialArgs = inputs;
          system = "aarch64-linux";
          modules = [
             ./malina5
          ];
        };
  };

  flake.deploy = {
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

  perSystem = { pkgs, lib, system, ... }:
    let
      # Only check the configurations for the current system
      sysConfigs = lib.filterAttrs (_name: value: value.pkgs.system == system) self.nixosConfigurations;
      deployRsChecks = (builtins.mapAttrs (_system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib).${system};
    in
    {
      # Add all the nixos configurations to the checks
      checks = (lib.mapAttrs' (name: value: { name = "nixos-toplevel-${name}"; value = value.config.system.build.toplevel; }) sysConfigs) // deployRsChecks;
    };
}
