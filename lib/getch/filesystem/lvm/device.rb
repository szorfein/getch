module Getch
  module FileSystem
    module Lvm
      class Device < Getch::FileSystem::Device
        def initialize
          super
          @vg = 'vg0'
          @lv_root = "/dev/mapper/#{@vg}-root"
          @lv_swap = "/dev/mapper/#{@vg}-swap"
          @lv_home = @home_disk ? "/dev/mapper/#{@vg}-home" : nil
        end

        private

        def search_boot
          if @boot_disk
            @dev_gpt = @efi ? nil : "/dev/#{@boot_disk}1"
            @dev_boot = @efi ? nil : "/dev/#{@boot_disk}2"
            @dev_esp = @efi ? "/dev/#{@boot_disk}1" : nil
          else
            @dev_gpt = @efi ? nil : "/dev/#{@disk}1"
            @dev_boot = @efi ? nil : "/dev/#{@disk}2"
            @dev_esp = @efi ? "/dev/#{@disk}1" : nil
            @root_part += 1
            @root_part += 1 if ! @efi
          end
        end
        
        # The swap is a part of the LVM volume, so we clean the func
        def search_swap
        end
      end
    end
  end
end
