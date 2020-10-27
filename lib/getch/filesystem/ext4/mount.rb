require 'fileutils'

module Getch
  module FileSystem
    module Ext4
      class Mount < Getch::FileSystem::Ext4::Device
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
          @mount.swap(@dev_swap)
          @mount.root(@dev_root)
          @mount.boot(@dev_boot)
          @mount.boot_efi(@dev_boot_efi)
          @mount.home(@dev_home)
          @state.mount
        end
      end
    end
  end
end
