require 'fileutils'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Mount < Getch::FileSystem::Ext4::Encrypt::Device
          def initialize
            super
            @root_dir = MOUNTPOINT
            @boot_dir = "#{@root_dir}/boot"
            @boot_efi_dir = "#{@root_dir}/boot/efi"
            @home_dir = @user ? "#{@root_dir}/home/#{@user}" : nil
            @state = Getch::States.new()
          end

          def run
            return if STATES[:mount]
            mount_swap
            mount_root
            mount_boot
            mount_home
            mount_boot_efi
            @state.mount
          end

          private

          def mount_swap
            return if ! @lv_swap
            system("swapon #{@lv_swap}")
          end

          def mount_root
            return if ! @lv_root
            Dir.mkdir(@root_dir, 0700) if ! Dir.exist?(@root_dir)
            system("mount #{@lv_root} #{@root_dir}")
          end

          def mount_boot_efi
            return if ! @dev_boot_efi
            FileUtils.mkdir_p @boot_efi_dir, mode: 0700 if ! Dir.exist?(@boot_efi_dir)
            system("mount #{@dev_boot_efi} #{@boot_efi_dir}")
          end

          def mount_boot
            return if ! @dev_boot
            FileUtils.mkdir_p @boot_dir, mode: 0700 if ! Dir.exist?(@boot_dir)
            system("mount #{@dev_boot} #{@boot_dir}")
          end

          def mount_home
            return if ! @lv_home
            if @user != nil then
              FileUtils.mkdir_p @home_dir, mode: 0700 if ! Dir.exist?(@home_dir)
              system("mount #{@lv_home} #{@home_dir}")
            end
            @state.mount
          end
        end
      end
    end
  end
end
