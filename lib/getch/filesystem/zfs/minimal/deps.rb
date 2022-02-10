# frozen_string_literal: true

require 'nito'

module Getch
  module FileSystem
    module Zfs
      module Minimal
        class Deps
          include NiTo

          def initialize
            x
          end

          protected

          def x
            unstable_zfs
            install_deps
            zfs_mountpoint
            hostid
            zed_update_path
          end

          private

          def unstable_zfs
            return unless OPTIONS[:os] == 'gentoo'

            conf = "#{OPTIONS[:mountpoint]}/etc/portage/package.accept_keywords/zfs"
            data = [
              'sys-fs/zfs-kmod',
              'sys-fs/zfs'
            ]
            File.write(conf, data.join("\n"), mode: 'w')
          end

          def install_deps
            case OPTIONS[:os]
            when 'gentoo' then Install.new('sys-fs/zfs')
            when 'void' then Install.new('zfs')
            end
          end

          # See: https://wiki.archlinux.org/index.php/ZFS#Using_zfs-mount-generator
          def zfs_mountpoint
            mkdir "#{MOUNTPOINT}/etc/zfs/zfs-list.cache"
            Helpers.touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@boot_pool_name}") if @dev_boot
            Helpers.touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@pool_name}")
            exec('ln -fs /usr/libexec/zfs/zed.d/history_event-zfs-list-cacher.sh /etc/zfs/zed.d/')
            add_service
          end

          def zed_update_path
            Dir.glob("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/*").each { |f|
              unless system('sed', '-Ei', "s|#{MOUNTPOINT}/?|/|", f)
                raise 'system exec sed'
              end
            }
          end

          def hostid
            exec 'zgenhostid $(hostid)'
          end

          def add_service
            systemd
            openrc
          end

          def systemd
            Helpers.systemd? || return

            exec('systemctl enable zfs-zed.service')
            exec('systemctl enable zfs.target')
            exec('systemctl enable zfs-zed.service')
          end

          def openrc
            Helpers.openrc? || return

            exec('rc-update add zfs-import boot')
            exec('rc-update add zfs-zed default')
          end

          def exec(cmd)
            Getch::Chroot.new(cmd)
          end
        end
      end
    end
  end
end
