module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Device
          def initialize
            @disk = DEFAULT_OPTIONS[:disk]
            @user = DEFAULT_OPTIONS[:username]
            @dev_boot_efi = Helpers::efi? ? "/dev/#{@disk}1" : nil
            @dev_boot = Helpers::efi? ? nil : "/dev/#{@disk}2"
            @dev_root = Helpers::efi? ? "/dev/#{@disk}2" : "/dev/#{@disk}3"
            @vg = 'vg0'
            @lv_root = "/dev/mapper/#{@vg}-root"
            @lv_swap = "/dev/mapper/#{@vg}-swap"
            @lv_home = @user ? "/dev/mapper/#{@vg}-home" : nil
            @luks_root = "/dev/mapper/cryptroot"
          end
        end
      end
    end
  end
end