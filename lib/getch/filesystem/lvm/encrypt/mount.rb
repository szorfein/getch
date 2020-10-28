module Getch
  module FileSystem
    module Lvm
      module Encrypt
        class Mount < Getch::FileSystem::Lvm::Encrypt::Device
          def initialize
            super
            @mount = Getch::FileSystem::Mount.new
            @state = Getch::States.new
          end

          def run
            return if STATES[:mount]
            @mount.swap(@lv_swap)
            @mount.root(@lv_root)
            @mount.boot(@dev_boot)
            @mount.esp(@dev_esp)
            @mount.home(@lv_home)
            @state.mount
          end
        end
      end
    end
  end
end
