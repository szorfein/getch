# frozen_string_literal: true

module Getch
  module FileSystem
    module Lvm
      module Encrypt
        class Format < Device
          def initialize
            super
            @fs = 'ext4'
            format
          end

          def format
            puts "Format #{@disk}"
            exec("mkfs.fat -F32 #{@dev_esp}") if @dev_esp
            exec("mkfs.#{@fs} -F #{@dev_boot}") if @dev_boot
            exec("mkfs.#{@fs} -F #{@lv_root}")
            exec("mkfs.#{@fs} -F #{@lv_home}") if @lv_home
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
