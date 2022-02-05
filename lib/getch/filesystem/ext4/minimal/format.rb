# frozen_string_literal: true

module Getch
  module FileSystem
    module Ext4
      module Minimal
        class Format
          def initialize
            super
            x
          end

          def x
            exec("mkfs.fat -F32 #{@dev_esp}") if @dev_esp
            exec("mkswap -f #{@dev_swap}")
            exec("mkfs.ext4 -F #{@dev_root}")
            exec("mkfs.ext4 -F #{@dev_home}") if @dev_home
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
