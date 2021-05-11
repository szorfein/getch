module Getch
  module FileSystem
    module Zfs
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
          if @efi
            if @boot_disk
              @dev_esp = "/dev/#{@boot_disk}1"
            else
              @dev_esp = "/dev/#{@disk}1"
              @root_part += 1
            end
          else
            if @boot_disk
              @dev_gpt = "/dev/#{@boot_disk}1"
              @dev_boot = "/dev/#{@boot_disk}2"
              @dev_grub = "/dev/#{@boot_disk}"
            else
              @dev_gpt = "/dev/#{@disk}1"
              @dev_boot = "/dev/#{@disk}2"
              @dev_grub = "/dev/#{@disk}"
              @root_part += 2
            end
          end
        end

        def search_swap
          if @cache_disk
            @dev_swap = "/dev/#{@cache_disk}1"
            @dev_log = "/dev/#{@cache_disk}2"
            @dev_cache = "/dev/#{@cache_disk}3"
          else
            @dev_swap = "/dev/#{@cache_disk}#{@root_part}"
            @root_part += 1
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
