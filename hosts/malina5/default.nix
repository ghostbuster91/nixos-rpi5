{ inputs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-linux";
  imports =
    [
      inputs.disko.nixosModules.disko
      inputs.impermanence.nixosModules.impermanence
      ./hw.nix
      ./disko-nvme-zfs.nix
      ./zfs.nix
      ./impermanence.nix
      ./kernel.nix
      ./network.nix
      ./system-user.nix
      # Further user configuration
      ./custom.nix
      ./nice-looking-console.nix
    ];
}
