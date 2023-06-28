{ disks ? [ "/dev/vdb" ], ... }: {
  disko.devices = {
    disk = {
      vdb = {
        type = "disk";
        device = builtins.elemAt disks 0;
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "UEFI";
              start = "1MiB";
              end = "512MiB";
              fs-type = "fat32";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
              };
            }
            {
              name = "swap";
              start = "512MiB";
              end = "1536MiB";
              part-type = "primary";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            }
            {
              name = "system";
              start = "1536MiB";
              end = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f --label system" ]; # Override existing partition and set a label called system
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@snapshots" = {
                  };
                };
              };
            }
          ];
        };
      };
    };
  };
}
