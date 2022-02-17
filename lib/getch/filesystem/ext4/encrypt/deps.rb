# frozen_string_literal: true

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Deps
          def initialize
            install
            service
          end

          protected

          def install
            case OPTIONS[:os]
            when 'gentoo' then Install.new('sys-fs/cryptsetup')
            when 'void' then Install.new('cryptsetup')
            end
          end

          def service
            openrc
          end

          def openrc
            Helpers.openrc? || return

            Chroot.new('rc-update add dmcrypt boot')
          end
        end
      end
    end
  end
end
