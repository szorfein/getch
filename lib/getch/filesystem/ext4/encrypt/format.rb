# frozen_string_literal: true

require 'mkfs'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Format
          def initialize
            x
          end

          private

          def x
            Mkfs::Encrypt.new(DEVS, OPTIONS)
          end
        end
      end
    end
  end
end
