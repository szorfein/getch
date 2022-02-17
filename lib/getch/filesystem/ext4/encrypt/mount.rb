# frozen_string_literal: true

require 'mountfs'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Mount
          def initialize
            x
          end

          private

          def x
            MountFs::Encrypt.new(DEVS, OPTIONS)
          end
        end
      end
    end
  end
end
