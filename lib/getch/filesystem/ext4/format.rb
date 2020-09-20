module Getch
  module FileSystem
    module Ext4
      class Format < Getch::FileSystem::Ext4::Device
        def initialize
          super
          @fs = 'ext4'
          @state = Getch::States.new()
          format
        end

        def format
          return if STATES[:format]
          puts "Format #{@disk} with #{@fs}"
          system("mkfs.fat -F32 #{@dev_boot_efi}") if Helpers::efi?
          system("mkswap -f #{@dev_swap}")
          system("mkfs.#{@fs} #{@dev_root}")
          system("mkfs.#{@fs} #{@dev_home}") if @dev_home
          @state.format
        end
      end
    end
  end
end
