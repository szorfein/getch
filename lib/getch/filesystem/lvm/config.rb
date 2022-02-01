# frozen_string_literal: true

require 'fstab'

module Getch
  module FileSystem
    module Lvm
      class Config < Getch::FileSystem::Lvm::Device
        def fstab
          devs = { esp: @dev_esp }
          Fstab::Lvm.new(devs, OPTIONS).generate
        end

        def cmdline
          conf = "#{MOUNTPOINT}/etc/dracut.conf.d/cmdline.conf"
          line = "resume=#{@lv_swap} rd.lvm.vg=#{@vg}"
          File.write conf, "kernel_cmdline=\"#{line}\"\n"
        end
      end
    end
  end
end
