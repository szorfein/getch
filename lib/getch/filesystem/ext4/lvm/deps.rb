# frozen_string_literal: true

module Getch
  module FileSystem
    module Ext4
      module Lvm
        class Deps
          def initialize
            x
          end

          protected

          def x
            case OPTIONS[:os]
            when 'gentoo' then gentoo_deps
            when 'void' then void_deps
            end
          end

          private

          def gentoo_deps
            #Getch::Bask.new('-a lvm')
            Install.new('sys-fs/lvm2')
            exec('systemctl enable lvm2-monitor')
          end

          def void_deps
          end

          def exec(cmd)
            Getch::Chroot.new(cmd)
          end
        end
      end
    end
  end
end
