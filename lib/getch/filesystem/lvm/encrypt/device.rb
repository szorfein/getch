# frozen_string_literal: true

module Getch
  module FileSystem
    module Lvm
      module Encrypt
        class Device < Getch::FileSystem::Device
          def initialize
            super
            @vg = OPTIONS[:vg_name] ||= 'vg0'
            @lv_root = "/dev/#{@vg}/root"
            @lv_swap = "/dev/#{@vg}/swap"
            @lv_home = @home_disk ? "/dev/#{@vg}/home" : nil
            @luks_root = '/dev/mapper/cryptroot'
            @luks_home = @home_disk ? '/dev/mapper/crypthome' : nil
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
          end
        end
      end
    end
  end
end
