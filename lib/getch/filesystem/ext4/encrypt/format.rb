# frozen_string_literal: true

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Format < Getch::FileSystem::Ext4::Encrypt::Device
          def initialize
            super
            format
          end

          def format
            exec("mkfs.fat -F32 #{@dev_esp}") if @dev_esp
            exec("mkfs.ext4 -F #{@luks_root}")
            exec("mkfs.ext4 -F #{@luks_home}") if @dev_home
          end

          private

          def exec(cmd)
            Getch::Command.new(cmd)
          end
        end
      end
    end
  end
end
