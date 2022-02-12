# frozen_string_literal: true

require 'nito'

module Getch
  module FileSystem
    module Zfs
      module Minimal
        class Deps
          include NiTo

          def initialize
            @mountpoint = OPTIONS[:mountpoint]
            @zfs = OPTIONS[:zfs_name] ||= 'pool'
            @os = OPTIONS[:os]
            x
          end

          protected

          def x
            unstable_zfs
            install_deps
            hostid
            zfs_mountpoint
            zed_update_path
            Command.new("zfs set canmount=on b#{@zfs}/BOOT/#{@os}") if DEVS[:boot]
            Log.new.fatal('zed - no pool') unless grep?("#{@mountpoint}/etc/zfs/zfs-list.cache/r#{@zfs}", "r#{@zfs}")
          end

          private

          def unstable_zfs
            return unless OPTIONS[:os] == 'gentoo'

            conf = "#{@mountpoint}/etc/portage/package.accept_keywords/zfs"
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
            exec("zpool set cachefile=/etc/zfs/b#{@zfs}.cache b#{@zfs}") if DEVS[:boot]
            exec("zpool set cachefile=/etc/zfs/r#{@zfs}.cache r#{@zfs}")
            exec('ln -fs /usr/libexec/zfs/zed.d/history_event-zfs-list-cacher.sh /etc/zfs/zed.d/')
            mkdir "#{@mountpoint}/etc/zfs/zfs-list.cache"
            touch "#{@mountpoint}/etc/zfs/zfs-list.cache/b#{@zfs}" if DEVS[:boot]
            touch "#{@mountpoint}/etc/zfs/zfs-list.cache/r#{@zfs}"
            add_service
          end

          def zed_update_path
            Dir.glob("#{@mountpoint}/etc/zfs/zfs-list.cache/*").each do |f|
              Command.new('sed', '-Ei', "\"s|#{@mountpoint}/?|/|\"", f)
            end
          end

          def hostid
            exec 'zgenhostid $(hostid)' unless File.exist? "#{@mountpoint}/etc/hostid"
          end

          def add_service
            systemd
            openrc
            runit
          end

          def systemd
            Helpers.systemd? || return

            exec('systemctl enable zfs-import-cache')
            exec('systemctl enable zfs-import.target')
            exec('systemctl enable zfs-zed.service')
            exec('systemctl enable zfs.target')
            exec('systemctl enable zfs-zed.service')
            fork_d('systemctl start zfs-zed.service')
          end

          def openrc
            Helpers.openrc? || return

            exec('rc-update add zfs-import boot')
            exec('rc-update add zfs-zed default')
            fork_d('zed -F')
          end

          def runit
            Helpers.runit? || return

            exec('ln -fs /etc/sv/zed /etc/runit/runsvdir/default/')
            fork_d('/etc/sv/zed/run')
          end

          def fork_d(cmd)
            job = fork do
              Getch::Chroot.new(cmd)
            end
            Process.detach(job)
            puts
          end

          def exec(cmd)
            Getch::Chroot.new(cmd)
          end
        end
      end
    end
  end
end
