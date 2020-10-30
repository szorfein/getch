module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Device < Getch::FileSystem::Device
          def initialize
            super
            @zfs_home = @user ? true : false
          end

          private

          def search_boot
            super
            if @boot_disk
              @dev_boot = @efi ? nil : "/dev/#{@boot_disk}2"
            else
              @dev_boot = @efi ? nil : "/dev/#{@disk}2"
              @root_part += 1 if ! @efi
            end
          end

          def search_root
            if @root_part == 1
              @dev_root = "/dev/#{@disk}"
            else
              @dev_root = "/dev/#{@disk}#{@root_part}"
            end
            @id = Helpers::pool_id(@dev_root)
            @boot_pool_name = "bpool-#{@id}"
            @pool_name = "rpool-#{@id}"
          end
        end
      end
    end
  end
end
