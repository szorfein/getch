# frozen_string_literal: true

module Getch
  module FileSystem
    module Ext4
      module Hybrid
        class Deps
          def initialize
            x
          end

          protected

          def x
            install
            service
          end

          def install
            case OPTIONS[:os]
            when 'gentoo' then Install.new('sys-fs/cryptsetup sys-fs/lvm2')
            when 'void' then Install.new('cryptsetup lvm2')
            end
          end

          def service
            systemd
            openrc
            runit
          end

          def systemd
            Helpers.systemd? || return

            exec('systemctl enable lvm2-monitor')
          end

          def openrc
            Helpers.openrc? || return

            exec('rc-update add lvm boot')
            exec('rc-update add dmcrypt boot')
          end

          def runit
          end

          def exec(cmd)
            Getch::Chroot.new(cmd)
          end
        end
      end
    end
  end
end
