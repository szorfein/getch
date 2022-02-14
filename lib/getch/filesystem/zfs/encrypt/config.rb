# frozen_string_literal: true

require 'fstab'
require 'dracut'
require 'cryptsetup'

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Config
          def initialize
            x
          end

          private

          def x
            Fstab::Zfs.new(DEVS, OPTIONS).generate
            Dracut::Zfs.new(DEVS, OPTIONS).generate
            CryptSetup.new(DEVS, OPTIONS).swap_conf
          end
        end
      end
    end
  end
end
