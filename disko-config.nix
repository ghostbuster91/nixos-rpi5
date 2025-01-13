{ disks ? [ "/dev/nvme0n1" ], ... }: {
  disko.devices = {
    disk =
      let
        commonZfsExtraOptions = [
          "--allow-discards"
          "--perf-no_write_workqueue"
          "--perf-no_read_workqueue"
        ];
      in
      {
        nvme0n1 = {
          type = "disk";
          device = builtins.elemAt disks 0;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "512M";
                type = "EF00";
                priority = 1;
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              root = {
                start = "1GB";
                end = "-64GB";
                content = {
                  type = "zfs";
                  pool = "rpool1";
                };
                priority = 2;
              };
              swap = {
                priority = 3;
                start = "-64G";
                end = "100%";
                content = {
                  type = "swap";
                };
              };
            };
          };
        };
      };
    zpool = {
      rpool1 =
        let
          unmountable = { type = "zfs_fs"; };
          filesystem = mountpoint: {
            type = "zfs_fs";
            options = {
              canmount = "noauto";
              inherit mountpoint;
            };
            inherit mountpoint;
          };
        in
        {
          type = "zpool";

          rootFsOptions = {
            compression = "lz4";
            "com.sun:auto-snapshot" = "false";
            canmount = "off";
            xattr = "sa";
            atime = "off";
          };
          options = {
            ashift = "12";
            autotrim = "on";
            compatibility = "grub2";
          };
          datasets = {
            "local" = unmountable;
            "local/root" = filesystem "/" // {
              postCreateHook = "zfs snapshot rpool1/local/root@blank";
            };
            "local/nix" = filesystem "/nix";
            "local/state" = filesystem "/state";

            "safe" = unmountable;
            "safe/persist" = filesystem "/persist";
          };
        };
    };
  };
}
