# frozen_string_literal: true

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Void < Device
          include Helpers::Void
          attr_reader :boot_disk

          def initialize
            super
            hostid
            zfs_zed # mountpoint for zfs
          end

          # Fstab contain:
          # > /efi noauto
          # > swap
          # > /boot zfs-legacy
          # > /tmp
          def fstab
            conf = "#{MOUNTPOINT}/etc/fstab"
            File.write(conf, "\n", mode: 'w', chmod: 0644)
            line_fstab(@dev_esp, "/efi vfat noauto,rw,relatime 0 0") if @dev_esp
            add_line(conf, '/dev/mapper/cryptswap none swap sw 0 0')
            add_line(conf, "##{@boot_pool_name}/BOOT/#{@n} /boot zfs defaults 0 0") if @dev_boot
            add_line(conf, 'tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0')
          end

          def config_dracut
            conf = "#{MOUNTPOINT}/etc/dracut.conf.d/zfs.conf"
            # dracut: value+= should be surrounding by white space
            content = [
              "hostonly=\"yes\"",
              "omit_dracutmodules+=\" btrfs lvm \"",
              "install_items+=\" /etc/crypttab \"",
            ]
            File.write(conf, content.join("\n"), mode: 'w', chmod: 0644)
          end

          def kernel_cmdline_dracut
            #command "zfs set mountpoint=legacy #{@boot_pool_name}/BOOT/#{@n}"
          end

          def config_grub
            grub_cmdline("root=zfs:#{@pool_name}/ROOT/#{@n}", "zfs_force=1")
          end

          def finish
            zed_update_path
            puts '+ Enter in your system: chroot /mnt /bin/bash'
            puts '+ Reboot with: shutdown -r now'
          end

          def crypttab
            line_crypttab('cryptswap', @dev_swap, '/dev/urandom', 'swap,discard,cipher=aes-xts-plain64:sha256,size=512')
          end

          private

          def line_crypttab(mapname, dev, point, rest)
            conf = "#{MOUNTPOINT}/etc/crypttab"
            device = s_uuid(dev)
            raise "No partuuid for #{dev} #{device}" unless device
            raise "Bad partuuid for #{dev} #{device}" if device.kind_of? Array

            add_line(conf, "#{mapname} PARTUUID=#{device} #{point} #{rest}")
          end

          def zfs_zed
            service_dir = '/etc/runit/runsvdir/default/'

            Helpers.mkdir("#{MOUNTPOINT}/etc/zfs/zfs-list.cache")
            Helpers.touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@boot_pool_name}") if @dev_boot
            Helpers.touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@pool_name}")
            fork { command '/etc/sv/zed/run' }
            command "ln -fs /etc/sv/zed #{service_dir}"
          end

          def zed_update_path
            Dir.glob("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/*").each { |f|
              unless system('sed', '-Ei', "s|#{MOUNTPOINT}/?|/|", f)
                raise 'System exec sed'
              end
            }
          end

          def hostid
            command 'zgenhostid $(hostid)'
          end
        end
      end
    end
  end
end
