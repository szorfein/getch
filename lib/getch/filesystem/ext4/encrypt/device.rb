module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Device
          def initialize
            @disk = DEFAULT_OPTIONS[:disk]
            @user = DEFAULT_OPTIONS[:username]
            @dev_boot_efi = Helpers::efi? ? "/dev/#{@disk}1" : nil
            @dev_root = "/dev/#{@disk}2"
            @vg = 'vg0'
            @lv_root = "/dev/mapper/#{@vg}-root"
            @lv_swap = "/dev/mapper/#{@vg}-swap"
            @lv_home = @user ? "/dev/mapper/#{@vg}-home" : nil
          end
        end
      end
    end
  end
end
