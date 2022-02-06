# frozen_string_literal: true

require 'devs'

module Getch
  module FileSystem
    module Ext4
      module Hybrid
        class Device
          def initialize
            @args = { start: true, boot: true, root: true }
            @vg = OPTIONS[:vg_name] ||= 'vg0'
            @lv_root = "/dev/#{@vg}/root"
            @lv_swap = "/dev/#{@vg}/swap"
            @lv_home = @home_disk ? "/dev/#{@vg}/home" : nil
            @luks_root = '/dev/mapper/cryptroot'
            @luks_home = @home_disk ? '/dev/mapper/crypthome' : nil
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
