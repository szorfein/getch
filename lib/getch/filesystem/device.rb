module Getch
  module FileSystem
    class Device
      def initialize
        @efi = Helpers::efi?
        @root_part = 1
        @user = DEFAULT_OPTIONS[:username]

        @disk = DEFAULT_OPTIONS[:disk]
        @boot_disk = DEFAULT_OPTIONS[:boot_disk]
        @cache_disk = DEFAULT_OPTIONS[:cache_disk]
        @home_disk = DEFAULT_OPTIONS[:home_disk]

        search_boot
        search_swap
        search_root
        search_home
      end

      private
      def search_boot
        if @boot_disk
          @dev_gpt = @efi ? nil : "/dev/#{@boot_disk}1"
          @dev_esp  = @efi ? "/dev/#{@boot_disk}1" : nil
        else
          @dev_gpt = @efi ? nil : "/dev/#{@disk}1"
          @dev_esp = @efi ? "/dev/#{@disk}1" : nil
          @boot_disk = @disk # used by grub
          @root_part += 1
        end
      end

      def search_swap
        if @cache_disk
          @dev_swap = "/dev/#{@cache_disk}1"
        else
          @dev_swap = "/dev/#{@disk}2"
          @root_part += 1
        end
      end

      def search_root
        @dev_root = "/dev/#{@disk}#{@root_part}"
      end

      def search_home
        if @home_disk
          @dev_home = "/dev/#{@home_disk}1"
        else
          @dev_home = nil
        end
      end
    end
  end
end
