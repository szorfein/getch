# frozen_string_literal: true

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Deps < Device
          def make
            unstable_zfs
            install_deps
            zfs_mountpoint
            hostid
            config_dracut
            zed_update_path
          end

          private

          def unstable_zfs
            conf = "#{MOUNTPOINT}/etc/portage/package.accept_keywords/zfs"
            data = [
              'sys-fs/zfs-kmod',
              'sys-fs/zfs'
            ]
            File.write(conf, data.join("\n"), mode: 'w')
          end

          def install_deps
            Getch::Emerge.new('sys-kernel/gentoo-kernel').pkg!
            Getch::Emerge.new('sys-fs/zfs').pkg!
          end

          # See: https://wiki.archlinux.org/index.php/ZFS#Using_zfs-mount-generator
          def zfs_mountpoint
            Helpers.mkdir("#{MOUNTPOINT}/etc/zfs/zfs-list.cache")
            Helpers.touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@boot_pool_name}") if @dev_boot
            Helpers.touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@pool_name}")
            exec('ln -fs /usr/libexec/zfs/zed.d/history_event-zfs-list-cacher.sh /etc/zfs/zed.d/')
            exec('systemctl start zfs-zed.service')
            exec('systemctl enable zfs-zed.service')
            exec('systemctl enable zfs.target')
          end

          def zed_update_path
            Dir.glob("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/*").each do |f|
              unless system('sed', '-Ei', "s|#{MOUNTPOINT}/?|/|", f)
                raise 'System exec sed'
              end
            end
          end

          def hostid
            exec 'zgenhostid $(hostid)'
          end

          def config_dracut
            conf = "#{MOUNTPOINT}/etc/dracut.conf.d/zfs.conf"
            content = 'hostonly="yes"'
            Helpers.echo conf, content
          end

          def exec(cmd)
            Getch::Chroot.new(cmd).run!
          end
        end
      end
    end
  end
end
