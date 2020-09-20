module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Format < Getch::FileSystem::Ext4::Encrypt::Device
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
            system("mkswap #{@lv_swap}")
            system("mkfs.#{@fs} #{@lv_root}")
            system("mkfs.#{@fs} #{@lv_home}") if @lv_home
            @state.format
          end
        end
      end
    end
  end
end
