require 'fileutils'

module Getch
  module FileSystem
    module Lvm
      class Mount < Getch::FileSystem::Lvm::Device
        def initialize
          super
          @root_dir = MOUNTPOINT
          @boot_dir = "#{@root_dir}/boot"
          @boot_efi_dir = "#{@root_dir}/boot/efi"
          @home_dir = @user ? "#{@root_dir}/home/#{@user}" : nil
          @mount = Getch::FileSystem::Mount.new
          @state = Getch::States.new
        end

        def run
          return if STATES[:mount]
          @mount.swap(@lv_swap)
          @mount.root(@lv_root)
          @mount.boot(@dev_boot)
          @mount.boot_efi(@dev_boot_efi)
          @mount.home(@lv_home)
          @state.mount
        end
      end
    end
  end
end
