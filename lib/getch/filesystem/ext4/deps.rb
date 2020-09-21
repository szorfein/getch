module Getch
  module FileSystem
    module Ext4
      class Deps
        def initialize
          if Helpers::efi?
            install_efi
          else
            install_bios
          end
        end

        private
        def install_efi
        end

        def install_bios
        end
      end
    end
  end
end
