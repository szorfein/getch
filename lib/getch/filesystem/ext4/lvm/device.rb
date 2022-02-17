# frozen_string_literal: true

require 'devs'

module Getch
  module FileSystem
    module Ext4
      module Lvm
        class Device
          def initialize
            @args = { start: true, root: true }
            @vg = OPTIONS[:vg_name] ||= 'vg0'
            @lv_root = "/dev/#{@vg}/root"
            @lv_swap = "/dev/#{@vg}/swap"
            @lv_home = @home_disk ? "/dev/#{@vg}/home" : nil
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
