{ config, ... }: {
  # This is identical to what nixos installer does in
  # (modulesPash + "profiles/installation-device.nix")

  # Use less privileged nixos user
  users.users.kghost = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
    # Allow the graphical user to login without password
    initialHashedPassword = "";
  };

  # Allow the user to log in as root without a password.
  users.users.root.initialHashedPassword = "";

  # Don't require sudo/root to `reboot` or `poweroff`.
  security.polkit.enable = true;

  # Allow passwordless sudo from nixos user
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Automatically log in at the virtual consoles.
  services.getty.autologinUser = "kghost";

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  # allow nix-copy to live system
  nix.settings.trusted-users = [ "kghost" ];

  # We are stateless, so just default to latest.
  system.stateVersion = config.system.nixos.release;
}
