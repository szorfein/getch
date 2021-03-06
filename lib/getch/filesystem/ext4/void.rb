require_relative '../../helpers'

module Getch
  module FileSystem
    module Ext4
      class Void < Device
        include Helpers::Void
        attr_reader :boot_disk

        def fstab
          conf = "#{MOUNTPOINT}/etc/fstab"
          File.write(conf, "\n", mode: 'w', chmod: 0644)
          line_fstab(@dev_esp, "/efi vfat noauto,rw,relatime 0 0") if @dev_esp
          line_fstab(@dev_swap, "swap swap rw,noatime,discard 0 0") if @dev_swap
          line_fstab(@dev_root, "/ ext4 rw,relatime 0 1")
          add_line(conf, "tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0")
        end

        def config_dracut
          conf = "#{MOUNTPOINT}/etc/dracut.conf.d/ext4.conf"
          # dracut: value+= should be surrounding by white space
          content = [
            "hostonly=\"yes\"",
            "omit_dracutmodules+=\" btrfs lvm \"",
            ""
          ]
          File.write(conf, content.join("\n"), mode: 'w', chmod: 0644)
        end

        def kernel_cmdline_dracut
          conf = "#{MOUNTPOINT}/etc/dracut.conf.d/cmdline.conf"
          c="kernel_cmdline=\"root=#{@dev_root} rootfstype=ext4 rootflags=rw,relatime\""
          File.write(conf, "#{c}\n", mode: 'w', chmod: 0644)
        end

        def finish
          puts "+ Enter in your system: chroot /mnt /bin/bash"
          puts "+ Reboot with: shutdown -r now"
        end
      end
    end
  end
end
