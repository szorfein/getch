# frozen_string_literal: true

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Deps < Minimal::Deps
          def install_deps
            case OPTIONS[:os]
            when 'gentoo' then Install.new('sys-fs/cryptsetup sys-fs/zfs')
            when 'void' then Install.new('cryptsetup zfs')
            end
          end
        end
      end
    end
  end
end
