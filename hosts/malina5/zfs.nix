{ lib
, pkgs
, ...
}: {
  boot.zfs = {
    devNodes = "/dev/disk/by-id";
    supportedFilesystems = [ "zfs" ];
  };

  networking.hostId = "8821e309"; # NOTE: for zfs, must be unique
  environment.systemPackages = with pkgs; [ zfs ];

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    trim = {
      enable = true;
      interval = "weekly";
    };
  };

  # services.telegraf.extraConfig.inputs = lib.mkIf config.services.telegraf.enable {
  #   zfs.poolMetrics = true;
  # };

  #services.prometheus.exporters = {
  #  zfs = {
  #    enable = true;
  #    port = 9004;
  #    openFirewall = true;
  #  };
  #};

  boot.initrd.postMountCommands = lib.mkAfter ''
    zfs rollback -r rpool1/local/root@blank
  '';
}
