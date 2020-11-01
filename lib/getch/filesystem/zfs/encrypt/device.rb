module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Device < Getch::FileSystem::Device
          def initialize
            super
            @id = Helpers::pool_id(@dev_root)
            @boot_pool_name = "bpool-#{@id}"
            @pool_name = "rpool-#{@id}"
            @zfs_home = @user ? true : false
          end

          private

          def search_boot
            if @boot_disk
              @dev_gpt = @efi ? nil : "/dev/#{@boot_disk}1"
              @dev_boot = @efi ? nil : "/dev/#{@boot_disk}2"
              @dev_esp  = @efi ? "/dev/#{@boot_disk}1" : nil
            else
              @dev_gpt = @efi ? nil : "/dev/#{@disk}#{@root_part}"
              @dev_esp = @efi ? "/dev/#{@disk}#{@root_part}" : nil
              @boot_disk = @disk # used by grub
              @root_part += 1
              @dev_boot = @efi ? nil : "/dev/#{@disk}#{@root_part}"
              @root_part += 1 if ! @efi
            end
          end

          def search_root
            if @root_part == 1
              @dev_root = "/dev/#{@disk}"
            else
              @dev_root = "/dev/#{@disk}#{@root_part}"
            end
          end
        end
      end
    end
  end
end
