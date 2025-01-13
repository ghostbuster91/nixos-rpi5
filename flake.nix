{
  description = "Malina 5";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

  };

  outputs = inputs @ { self, nixpkgs, raspberry-pi-nix, ... }:
    let
      inherit (nixpkgs.lib) nixosSystem;
      basic-config = { pkgs, lib, ... }: {
        # bcm2711 for rpi 3, 3+, 4, zero 2 w
        # bcm2712 for rpi 5
        # See the docs at:
        # https://www.raspberrypi.com/documentation/computers/linux_kernel.html#native-build-configuration
        raspberry-pi-nix.board = "bcm2712";
        time.timeZone = "Warsaw/Poland";
        users.users.root = {
          initialPassword = "root";
        };
        # Define a user account. Don't forget to set a password with ‘passwd’.
        users.users.kghost = {
          isNormalUser = true;
          extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
          initialPassword = "arstarst";

          openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFFeU4GXH+Ae00DipGGJN7uSqPJxWFmgRo9B+xjV3mK4" ];
        };

        boot.supportedFilesystems = [ "zfs" ];
        boot.kernelModules = [ "zfs" ];
        boot.initrd.availableKernelModules = [ "zfs" ];

        networking = {
          hostName = "malina5";
          hostId = "8dd1a082";

        };
        environment.systemPackages = with pkgs; [
          neovim
          git
          wget
        ];
        services.openssh = {
          enable = true;
        };
        system.stateVersion = "24.11";
      };
      pkgs = (import inputs.nixpkgs {
        system = "aarch64-linux";
        config.allowUnfree = true;
      });

    in
    let

      system = "aarch64-linux";
    in
    {
      nixosConfigurations = {
        malina5 = nixosSystem {
          system = "aarch64-linux";
          modules = [
            raspberry-pi-nix.nixosModules.raspberry-pi
            basic-config
            inputs.disko.nixosModules.default
            (import ./disko-config.nix {
              disks = [ "/dev/nvme0n1" ];
            })
            ./impermanence.nix
            inputs.impermanence.nixosModules.impermanence
          ];
        };

        malina5sd = nixosSystem {
          system = "aarch64-linux";
          modules = [
            raspberry-pi-nix.nixosModules.raspberry-pi
            raspberry-pi-nix.nixosModules.sd-image
            ./installer-configuration.nix
            basic-config
            inputs.disko.nixosModules.default
            ({ config
             , lib
             , pkgs
             , ...
             }:
              let
                # disko
                disko = pkgs.writeShellScriptBin "disko" ''${config.system.build.diskoScript}'';
                disko-mount = pkgs.writeShellScriptBin "disko-mount" "${config.system.build.mountScript}";
                disko-format = pkgs.writeShellScriptBin "disko-format" "${config.system.build.formatScript}";
                disko-destroy = pkgs.writeShellScriptBin "disko-destroy" "${config.system.build.destroyScriptNoDeps}";

                # system
                inherit system;

                install-system = pkgs.writeShellScriptBin "install-system" ''
                  set -euo pipefail

                  echo "Formatting disks..."
                  . ${disko-format}/bin/disko-format

                  echo "Mounting disks..."
                  . ${disko-mount}/bin/disko-mount

                  echo "Installing system..."
                  nixos-install --system ${system}

                  echo "Done!"
                '';
              in
              {
                imports = [
                  (import ./disko-config.nix { })
                ];

                # we don't want to generate filesystem entries on this image
                disko.enableConfig = lib.mkDefault false;

                boot.zfs.forceImportRoot = false;

                # add disko commands to format and mount disks
                environment.systemPackages = [
                  disko
                  disko-mount
                  disko-format
                  disko-destroy
                  install-system
                ];
              })
          ];
        };
      };
      # For each major system, we provide a customized installer image that
      # has ssh and some other convenience stuff preconfigured.
      # Not strictly necessary for new setups.
      packages.live-iso = inputs.nixos-generators.nixosGenerate {
        inherit pkgs;
        modules = [
          inputs.disko.nixosModules.disko
          ./installer-configuration.nix
          ({ config
           , lib
           , pkgs
           , ...
           }:
            let
              # disko
              disko = pkgs.writeShellScriptBin "disko" ''${config.system.build.diskoScript}'';
              disko-mount = pkgs.writeShellScriptBin "disko-mount" "${config.system.build.mountScript}";
              disko-format = pkgs.writeShellScriptBin "disko-format" "${config.system.build.formatScript}";
              disko-destroy = pkgs.writeShellScriptBin "disko-destroy" "${config.system.build.destroyScriptNoDeps}";

              # system
              inherit system;

              install-system = pkgs.writeShellScriptBin "install-system" ''
                set -euo pipefail

                echo "Formatting disks..."
                . ${disko-format}/bin/disko-format

                echo "Mounting disks..."
                . ${disko-mount}/bin/disko-mount

                echo "Installing system..."
                nixos-install --system ${system}

                echo "Done!"
              '';
            in
            {
              imports = [
                (import ./disko-config.nix { })
              ];

              # we don't want to generate filesystem entries on this image
              disko.enableConfig = lib.mkDefault false;

              # add disko commands to format and mount disks
              environment.systemPackages = [
                disko
                disko-mount
                disko-format
                disko-destroy
                install-system
              ];
            })
        ];
        format =
          {
            x86_64-linux = "install-iso";
            aarch64-linux = "sd-aarch64-installer";
          }.${system};
      };
    };
  nixConfig = {
    # Only during the first build, otherwise I don't want to allow such a binary cache
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
