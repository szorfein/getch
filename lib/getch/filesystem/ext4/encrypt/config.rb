# frozen_string_literal: true

require 'fstab'
require 'dracut'
require 'cryptsetup'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Config
          def initialize
            x
          end

          private

          def x
            Fstab::Encrypt.new(DEVS, OPTIONS).generate
            CryptSetup.new(DEVS, OPTIONS).configs
            Dracut::Encrypt.new(DEVS, OPTIONS).generate
          end
        end
      end
    end
  end
end
