# frozen_string_literal: true

require 'fstab'
require 'dracut'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Config
          def initialize
            x
          end

          protected

          def x
            Fstab::Encrypt.new(DEVS, OPTIONS).generate
            Dracut::Encrypt.new(DEVS, OPTIONS).generate
            grub
          end

          def grub
            Helpers.grub? || return

            file = "#{@root_dir}/etc/default/grub"
            echo_a file, 'GRUB_ENABLE_CRYPTODISK=y'
          end
        end
      end
    end
  end
end
