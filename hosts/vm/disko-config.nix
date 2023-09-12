{ disks ? [ "/dev/vda" ], ... }: {
  disko.devices = {
    disk = {
      vdb = {
        type = "disk";
        device = builtins.elemAt disks 0;
        #device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
              };
            };
            root = {
              end = "-4G";
              content = {
                type = "btrfs";
                extraArgs = [ "-f --label system" ]; # Override existing partition and set a label called system
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  "@" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/";
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@snapshots" = {
                  };
                };
              };
            };
            swap = {
              size = "100%";
              content = {
                type = "swap";
                randomEncryption = true;
                resumeDevice = true; # resume from hiberation from this device
              };
            };
          };
        };
      };
    };
  };
}
