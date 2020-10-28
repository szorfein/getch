module Getch
  module FileSystem
    module Ext4
      class Mount < Getch::FileSystem::Ext4::Device
        def initialize
          super
          @mount = Getch::FileSystem::Mount.new
          @state = Getch::States.new
        end

        def run
          return if STATES[:mount]
          @mount.swap(@dev_swap)
          @mount.root(@dev_root)
          @mount.boot(@dev_boot)
          @mount.esp(@dev_esp)
          @mount.home(@dev_home)
          @state.mount
        end
      end
    end
  end
end
