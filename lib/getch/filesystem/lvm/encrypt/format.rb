module Getch
  module FileSystem
    module Lvm
      module Encrypt
        class Format < Getch::FileSystem::Lvm::Encrypt::Device
          def initialize
            super
            @fs = 'ext4'
            @state = Getch::States.new()
            format
          end

          def format
            return if STATES[:format]
            puts "Format #{@disk} with #{@fs}"
            exec("mkfs.fat -F32 #{@dev_boot_efi}") if @dev_boot_efi
            exec("mkfs.#{@fs} -F #{@dev_boot}") if @dev_boot
            exec("mkswap -f #{@lv_swap}")
            exec("mkfs.#{@fs} -F #{@lv_root}")
            exec("mkfs.#{@fs} -F #{@lv_home}") if @lv_home
            @state.format
          end

          private
          def exec(cmd)
            Getch::Command.new(cmd).run!
          end
        end
      end
    end
  end
end
