require_relative '../../helpers'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Void < Device
          include Helpers::Void
          attr_reader :boot_disk

          # Create key to avoid enter password twice
          def create_key
            command "dd bs=1 count=64 if=/dev/urandom of=/boot/volume.key"
            command "cryptsetup luksAddKey #{@dev_root} /boot/volume.key"
            command "chmod 000 /boot/volume.key"
            command "chmod -R g-rwx,o-rwx /boot"
          end

          def fstab
            conf = "#{MOUNTPOINT}/etc/fstab"
            File.write(conf, "\n", mode: 'w', chmod: 0644)
            line_fstab(@dev_esp, "/efi vfat noauto,rw,relatime 0 0") if @dev_esp
            add_line(conf, "#{@luks_swap} none swap discard 0 0") if @dev_swap
            add_line(conf, "#{@luks_root} / ext4 rw,relatime 0 1")
            add_line(conf, "tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0")
          end

          def crypttab
            conf = "#{MOUNTPOINT}/etc/crypttab"
            File.write(conf, "\n", mode: 'w', chmod: 0644)
            line_crypttab("cryptswap", @dev_swap, "/dev/urandom", "luks") if @dev_swap
            line_crypttab("cryptroot", @dev_root, "/boot/volume.key", "luks")
          end

          def config_grub
            conf = "#{MOUNTPOINT}/etc/default/grub"
            content = [
              "GRUB_ENABLE_CRYPTODISK=y",
              ""
            ]
            File.write(conf, content.join("\n"), mode: 'a', chmod: 644)
          end

          def config_dracut
            conf = "#{MOUNTPOINT}/etc/dracut.conf.d/ext4.conf"
            content = [
              "hostonly=\"yes\"",
              "omit_dracutmodules+=\" btrfs lvm \"",
              "compress=\"zstd\"",
              "install_items+=\" /boot/volume.key /etc/crypttab \"",
              ""
            ]
            File.write(conf, content.join("\n"), mode: 'w', chmod: 0644)
          end

          def kernel_cmdline_dracut
            conf = "#{MOUNTPOINT}/etc/dracut.conf.d/cmdline.conf"
            root_uuid = b_uuid(@dev_root)
            args = "rd.luks.uuid=#{root_uuid} rootfstype=ext4 rootflags=rw,relatime"
            line = "kernel_cmdline=\"#{args}\""
            File.write(conf, "#{line}\n", mode: 'w', chmod: 0644)
          end

          def finish
            puts "+ Enter in your system: chroot /mnt /bin/bash"
            puts "+ Reboot with: shutdown -r now"
          end

          private

          def b_uuid(dev)
            device = dev.delete_prefix("/dev/")
            Dir.glob("/dev/disk/by-uuid/*").each { |f|
              link = File.readlink(f)
              return f.delete_prefix("/dev/disk/by-uuid/") if link.match(/#{device}$/)
            }
          end

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

          # line_crypttab("cryptswap", "sda2", "/dev/urandom", "luks")
          def line_crypttab(mapname, dev, point, rest)
            conf = "#{MOUNTPOINT}/etc/crypttab"
            device = b_uuid(dev)
            raise "No partuuid for #{dev} #{device}" if !device
            raise "Bad partuuid for #{dev} #{device}" if device.kind_of? Array
            add_line(conf, "#{mapname} UUID=#{device} #{point} #{rest}")
          end
        end
      end
    end
  end
end
