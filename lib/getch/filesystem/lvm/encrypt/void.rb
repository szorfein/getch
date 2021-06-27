require_relative '../../../helpers'

module Getch
  module FileSystem
    module Lvm
      module Encrypt
        class Void < Device
          include Helpers::Void
          attr_reader :boot_disk

          # Create key to avoid enter password twice
          def create_key
            add_key("volume.key", @dev_root)
            add_key("home.key", @dev_home) if @home_disk
          end

          # Key need to be added in dracut.conf.d and crypttab
          def add_key(name, dev)
            command "dd bs=1 count=64 if=/dev/urandom of=/boot/#{name}"
            puts " => Creating a key for #{dev}, password required:"
            chroot "cryptsetup luksAddKey #{dev} /boot/#{name}"
            command "chmod 000 /boot/#{name}"
            #command "chmod -R g-rwx,o-rwx /boot"
          end

          def fstab
            conf = "#{MOUNTPOINT}/etc/fstab"
            File.write(conf, "\n", mode: 'w', chmod: 0644)
            line_fstab(@dev_esp, "/efi vfat noauto,rw,relatime 0 0") if @dev_esp
            line_fstab(@dev_boot, "/boot ext4 noauto,rw,relatime 0 0") if @dev_boot
            add_line(conf, "/dev/mapper/cryptswap none swap discard 0 0")
            add_line(conf, "#{@lv_home} /home ext4 rw,discard 0 0") if @home_disk
            add_line(conf, "#{@lv_root} / ext4 rw,relatime 0 1")
            add_line(conf, "tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0")
          end

          def crypttab
            conf = "#{MOUNTPOINT}/etc/crypttab"
            File.write(conf, "\n", mode: 'w', chmod: 0644)
            add_line(conf, "#{@lv_swap} /dev/urandom swap,cipher=aes-xts-plain64:sha256,size=512")
            line_crypttab("cryptroot", @dev_root, "/boot/volume.key", "luks")
            line_crypttab("crypthome", @dev_home, "/boot/home.key", "luks") if @home_disk
          end

          def config_grub
            conf = "#{MOUNTPOINT}/etc/default/grub"
            content = "GRUB_ENABLE_CRYPTODISK=y"
            unless search(conf, content)
              File.write(conf, "#{content}\n", mode: 'a')
            end
          end

          def config_dracut
            conf = "#{MOUNTPOINT}/etc/dracut.conf.d/lvm.conf"
            content = [
              "hostonly=\"yes\"",
              "omit_dracutmodules+=\" btrfs \"",
              "install_items+=\" /boot/volume.key /etc/crypttab \"",
              ""
            ]
            File.write(conf, content.join("\n"), mode: 'w', chmod: 0644)
            #add_line(conf, "install_items+=\" /boot/home.key \"") if @home_disk
          end

          def kernel_cmdline_dracut
            conf = "#{MOUNTPOINT}/etc/dracut.conf.d/cmdline.conf"
            root_uuid = b_uuid(@dev_root)
            args = "rd.lvm.vg=#{@vg} rd.luks.uuid=#{root_uuid} rootflags=rw,relatime"
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
            device = s_uuid(dev)
            raise "No partuuid for #{dev} #{device}" if !device
            raise "Bad partuuid for #{dev} #{device}" if device.kind_of? Array
            add_line(conf, "#{mapname} PARTUUID=#{device} #{point} #{rest}")
          end
        end
      end
    end
  end
end
