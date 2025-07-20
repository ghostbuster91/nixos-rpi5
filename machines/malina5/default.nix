{ inputs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-linux";

  imports =
    [
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.bluetooth
            ./configuration.nix
            ./monitoring.nix
            ./pi5-config.nix
    ];

}
