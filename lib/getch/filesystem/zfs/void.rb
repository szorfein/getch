require_relative '../../helpers'

module Getch
  module FileSystem
    module Zfs
      class Void < Device
        include Helpers::Void
        attr_reader :boot_disk

        def fstab
          conf = "#{MOUNTPOINT}/etc/fstab"
          File.write(conf, "\n", mode: 'w', chmod: 0644)
          line_fstab(@dev_esp, "/efi vfat noauto,rw,relatime 0 0") if @dev_esp
          line_fstab(@dev_swap, "swap swap rw,noatime,discard 0 0") if @dev_swap
          add_line(conf, "tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0")
        end

        def config_dracut
          conf = "#{MOUNTPOINT}/etc/dracut.conf.d/zfs.conf"
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
          c="kernel_cmdline=\"root=#{@dev_root} rootflags=rw,relatime\""
          File.write(conf, "#{c}\n", mode: 'w', chmod: 0644)
        end

        def finish
          puts "+ Enter in your system: chroot /mnt /bin/bash"
          puts "+ Reboot with: shutdown -r now"
        end

        private

        def s_uuid(dev)
          device = dev.delete_prefix("/dev/")
          Dir.glob("/dev/disk/by-partuuid/*").each { |f|
            link = File.readlink(f)
            return f.delete_prefix("/dev/disk/by-partuuid/") if link.match(/#{device}$/)
          }
        end

        def line_fstab(dev, rest)
          conf = "#{MOUNTPOINT}/etc/fstab"
          device = s_uuid(dev)
          raise "No partuuid for #{dev} #{device}" if !device
          raise "Bad partuuid for #{dev} #{device}" if device.kind_of? Array
          add_line(conf, "PARTUUID=#{device} #{rest}")
        end

        def add_line(file, line)
          raise "No file #{file} found !" unless File.exist? file
          File.write(file, "#{line}\n", mode: 'a')
        end
      end
    end
  end
end
