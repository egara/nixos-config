{ disks ? [ "/dev/sda" ], ... }: {
  disko.devices = {
    disk = {
      vdb = {
        type = "disk";
        device = builtins.elemAt disks 0;
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            # UEFI
            {
              name = "UEFI";
              start = "1MiB";
              end = "513MiB";
              fs-type = "fat32";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
              };
            }
 
            # SWAP
            {
              name = "swap";
              start = "513MiB";
              end = "8537MiB";
              part-type = "primary";
              fs-type = "linux-swap";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            }

            # SYSTEM
            {
              name = "system";
              start = "8537MiB";
              end = "100%";
              content = {
                type = "btrfs";

                # Override existing partition and set a label called system
                extraArgs = [ "-f --label system" ];

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
