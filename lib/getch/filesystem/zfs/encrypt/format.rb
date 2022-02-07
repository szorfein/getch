# frozen_string_literal: true

require 'mkfs'

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Format
          def initialize
            x
          end

          private

          def x
            Mkfs::Zfs.new(DEVS, OPTIONS)
          end
        end
      end
    end
  end
end
