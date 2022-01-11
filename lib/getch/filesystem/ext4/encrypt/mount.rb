# frozen_string_literal: true

require 'fileutils'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Mount < Getch::FileSystem::Ext4::Encrypt::Device
          def initialize
            super
            @mount = Getch::FileSystem::Mount.new
            @state = Getch::States.new()
          end

          def run
            return if STATES[:mount]

            @mount.root(@luks_root)
            @mount.boot(@dev_boot)
            @mount.esp(@dev_esp)
            @mount.home(@luks_home)
            @state.mount
          end
        end
      end
    end
  end
end
