# frozen_string_literal: true

require 'fstab'

module Getch
  module FileSystem
    module Lvm
      class Config < Getch::FileSystem::Lvm::Device
        def fstab
          devs = { esp: @dev_esp, boot: @dev_boot }
          Fstab.new(devs, OPTIONS).generate

          file = "#{MOUNTPOINT}/etc/fstab"
          datas = data_fstab
          File.write(file, datas.join("\n"))
        end

        def cmdline
          conf = "#{MOUNTPOINT}/etc/dracut.conf.d/cmdline.conf"
          line = "resume=#{@lv_swap} rd.lvm.vg=#{@vg}"
          File.write conf, "kernel_cmdline=\"#{line}\"\n"
        end

        private

        def data_fstab
          swap = "#{@lv_swap} none swap discard 0 0"
          root = "#{@lv_root} / ext4 defaults 0 1"
          home = @lv_home ? "#{@lv_home} /home/#{@user} ext4 defaults 0 2" : ''

          [ swap, root, home ]
        end
      end
    end
  end
end
