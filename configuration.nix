{ pkgs, lib, ... }: {
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
  swapDevices = [
    {
      device = "/dev/nvme0n1p3";
    }
  ];

  networking = {
    hostName = "malina5";
    hostId = "8dd1a082";

  };
  environment.systemPackages = with pkgs; [
    neovim
    git
    wget
    htop
  ];
  services.openssh = {
    enable = true;
  };
  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
      };
      allowInterfaces = [ "end0" "wlan0" ];
    };
  };
  nix = {
    # Automate garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 60d";
    };

    # Flakes settings
    package = pkgs.nixVersions.stable;

    settings = {
      # Automate `nix store --optimise`
      auto-optimise-store = true;

      # Required by Cachix to be used as non-root user
      trusted-users = [ "root" "kghost" ];

      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;

      # Avoid unwanted garbage collection when using nix-direnv
      keep-outputs = true;
      keep-derivations = true;
    };
  };
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "24.11";
}
