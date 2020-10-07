module Getch
  module FileSystem
    module Zfs
      class Format < Getch::FileSystem::Zfs::Device
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
          system("mkswap -f #{@dev_swap}")
          @state.format
        end
      end
    end
  end
end
