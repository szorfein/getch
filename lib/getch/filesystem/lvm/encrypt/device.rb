module Getch
  module FileSystem
    module Lvm
      module Encrypt
        class Device < Getch::FileSystem::Device
          def initialize
            super
            @vg = 'vg0'
            @lv_root = "/dev/mapper/#{@vg}-root"
            @lv_swap = "/dev/mapper/#{@vg}-swap"
            @lv_home = @home_disk ? "/dev/mapper/#{@vg}-home" : nil
            @luks_root = "/dev/mapper/cryptroot"
            @luks_home = @home_disk ? "/dev/mapper/crypthome" : nil
          end

          private

          def search_boot
            if @boot_disk
              @dev_gpt = @efi ? nil : "/dev/#{@boot_disk}1"
              @dev_boot = @efi ? nil : "/dev/#{@boot_disk}2"
              @dev_esp = @efi ? "/dev/#{@boot_disk}2" : nil
            else
              @dev_gpt = @efi ? nil : "/dev/#{@disk}1"
              @dev_boot = @efi ? nil : "/dev/#{@disk}2"
              @dev_esp = @efi ? "/dev/#{@disk}2" : nil
              @root_part += 1
              @root_part += 1 if ! @efi
            end
          end

          def search_swap
          end
        end
      end
    end
  end
end
