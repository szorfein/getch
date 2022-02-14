# frozen_string_literal: true

require 'fstab'
require 'dracut'
require 'cryptsetup'

module Getch
  module FileSystem
    module Ext4
      module Hybrid
        class Config
          def initialize
            x
          end

          private

          def x
            Fstab::Hybrid.new(DEVS, OPTIONS).generate
            Dracut::Hybrid.new(DEVS, OPTIONS).generate
            CryptSetup.new(DEVS, OPTIONS).configs
          end
        end
      end
    end
  end
end
