# frozen_string_literal: true

module Getch
  module FileSystem
    module Lvm
      module Encrypt
        class Void < Device
          include Helpers::Void

          attr_reader :boot_disk

          # Create key to avoid enter password twice
          def create_key
            add_key('volume.key', @dev_root)
            add_key('home.key', @dev_home) if @home_disk
          end

          # Key need to be added in dracut.conf.d and crypttab
          def add_key(name, dev)
            command "dd bs=1 count=64 if=/dev/urandom of=/boot/#{name}"
            puts " => Creating a key for #{dev}, password required:"
            chroot "cryptsetup luksAddKey #{dev} /boot/#{name}"
            command "chmod 000 /boot/#{name}"
            #command "chmod -R g-rwx,o-rwx /boot"
          end

          def crypttab
            conf = "#{MOUNTPOINT}/etc/crypttab"
            File.write(conf, "\n", mode: 'w', chmod: 0644)
            add_line(conf, "cryptswap #{@lv_swap} /dev/urandom swap,discard,cipher=aes-xts-plain64:sha256,size=512")
            line_crypttab(@vg, @dev_root, '/boot/volume.key', 'luks')
            line_crypttab("crypthome", @dev_home, "/boot/home.key", "luks") if @home_disk
          end

          def config_dracut
            conf = "#{MOUNTPOINT}/etc/dracut.conf.d/lvm.conf"
            content = [
              'hostonly="yes"',
              'omit_dracutmodules+=" btrfs "',
              'install_items+=" /boot/volume.key /etc/crypttab "',
              ''
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
            puts '+ Enter in your system: chroot /mnt /bin/bash'
            puts '+ Reboot with: shutdown -r now'
          end

          private

          def b_uuid(dev)
            device = dev.delete_prefix('/dev/')
            Dir.glob('/dev/disk/by-uuid/*').each { |f|
              link = File.readlink(f)
              return f.delete_prefix('/dev/disk/by-uuid/') if link.match(/#{device}$/)
            }
          end

          # line_crypttab("cryptswap", "sda2", "/dev/urandom", "luks")
          def line_crypttab(mapname, dev, point, rest)
            conf = "#{MOUNTPOINT}/etc/crypttab"
            device = s_uuid(dev)
            raise "No partuuid for #{dev} #{device}" unless device
            raise "Bad partuuid for #{dev} #{device}" if device.kind_of? Array
            add_line(conf, "#{mapname} PARTUUID=#{device} #{point} #{rest}")
          end
        end
      end
    end
  end
end
