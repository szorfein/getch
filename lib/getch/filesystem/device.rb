# frozen_string_literal: true

module Getch
  module FileSystem
    class Device
      def initialize
        @efi = Helpers.efi?
        @root_part = 1
        @user = Getch::OPTIONS[:username]

        @disk = Getch::OPTIONS[:disk]
        @boot_disk = Getch::OPTIONS[:boot_disk]
        @cache_disk = Getch::OPTIONS[:cache_disk]
        @home_disk = Getch::OPTIONS[:home_disk]

        search_boot
        search_swap
        search_root
        search_home
      end

      private
      def search_boot
        if @efi
          if @boot_disk
            @dev_esp = "/dev/#{@boot_disk}#{@root_part}"
          else
            @dev_esp = "/dev/#{@disk}#{@root_part}"
            @root_part += 1
          end
        else
          if @boot_disk
            @dev_gpt = "/dev/#{@boot_disk}#{@root_part}"
            @dev_grub = "/dev/#{@boot_disk}"
          else
            @dev_gpt = "/dev/#{@disk}#{@root_part}"
            @dev_grub = "/dev/#{@disk}"
            @root_part += 1
          end
        end
      end

      def search_swap
        if @cache_disk
          @dev_swap = "/dev/#{@cache_disk}1"
        else
          @dev_swap = "/dev/#{@disk}#{@root_part}"
          @root_part += 1
        end
      end

      def search_root
        @dev_root = "/dev/#{@disk}#{@root_part}"
      end

      def search_home
        if @home_disk
          @dev_home = "/dev/#{@home_disk}1"
        end
      end
    end
  end
end
