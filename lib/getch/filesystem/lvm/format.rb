module Getch
  module FileSystem
    module Lvm
      class Format < Getch::FileSystem::Lvm::Device
        def initialize
          super
          @fs = 'ext4'
          @state = Getch::States.new()
          format
        end

        def format
          return if STATES[:format]
          puts "Format #{@disk} with #{@fs}"
          system("mkfs.fat -F32 #{@dev_boot_efi}") if @dev_boot_efi
          system("mkfs.#{@fs} -F #{@dev_boot}") if @dev_boot
          system("mkswap -f #{@lv_swap}")
          system("mkfs.#{@fs} -F #{@lv_root}")
          system("mkfs.#{@fs} -F #{@lv_home}") if @lv_home
          @state.format
        end
      end
    end
  end
end
