# frozen_string_literal: true

require 'nito'

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Void < Device
          include NiTo
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
            add_line(conf, 'tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0')
          end

          def finish
            zed_update_path
            puts '+ Enter in your system: chroot /mnt /bin/bash'
            puts '+ Reboot with: shutdown -r now'
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

            mkdir "#{MOUNTPOINT}/etc/zfs/zfs-list.cache"
            Helpers.touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@boot_pool_name}") if @dev_boot
            Helpers.touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@pool_name}")
            fork { command '/etc/sv/zed/run' }
            command "ln -fs /etc/sv/zed #{service_dir}"
          end

          def zed_update_path
            Dir.glob("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/*").each do |f|
              unless system('sed', '-Ei', "s|#{MOUNTPOINT}/?|/|", f)
                raise 'System exec sed'
              end
            end
          end

          def hostid
            command 'zgenhostid $(hostid)'
          end
        end
      end
    end
  end
end
