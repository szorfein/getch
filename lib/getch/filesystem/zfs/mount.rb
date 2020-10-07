require 'fileutils'

module Getch
  module FileSystem
    module Zfs
      class Mount < Getch::FileSystem::Zfs::Device
        def initialize
          super
          @root_dir = MOUNTPOINT
          @boot_dir = "#{@root_dir}/boot"
          @boot_efi_dir = "#{@root_dir}/boot/efi"
          @state = Getch::States.new()
        end

        def run
          return if STATES[:mount]
          mount_swap
          mount_root
          mount_boot
          mount_boot_efi
          @state.mount
        end

        private

        def mount_swap
          system("swapon #{@dev_swap}")
        end

        def mount_root
          Dir.mkdir(@root_dir, 0700) if ! Dir.exist?(@root_dir)
          system("zfs mount #{@pool_name}/ROOT/gentoo")
        end

        def mount_boot_efi
          return if ! @dev_boot_efi
          FileUtils.mkdir_p @boot_efi_dir, mode: 0700 if ! Dir.exist?(@boot_efi_dir)
          system("mount #{@dev_boot_efi} #{@boot_efi_dir}")
        end

        def mount_boot
          return if ! @dev_boot
          FileUtils.mkdir_p @boot_dir, mode: 0700 if ! Dir.exist?(@boot_dir)
          system("zfs mount #{@boot_pool_name}/BOOT/gentoo")
        end
      end
    end
  end
end
