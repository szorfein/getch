# frozen_string_literal: true

require 'devs'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Device
          def initialize
            @args = { start: true, boot: true, swap: true, root: true }
            @luks_root = '/dev/mapper/cryptroot'
            @luks_home = @home_disk ? '/dev/mapper/crypthome' : nil
            @luks_swap = '/dev/mapper/cryptswap'
            x
          end

          private

          def x
            Devs::Settings.new(@args, OPTIONS)
          end
        end
      end
    end
  end
end
