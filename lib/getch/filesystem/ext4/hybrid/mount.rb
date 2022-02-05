# frozen_string_literal: true

module Getch
  module FileSystem
    module Ext4
      module Hybrid
        class Mount
          def initialize
            @mount = Getch::FileSystem::Mount.new
          end

          def run
            @mount.root(@lv_root)
            @mount.boot(@dev_boot)
            @mount.esp(@dev_esp)
            @mount.home(@lv_home)
          end
        end
      end
    end
  end
end
