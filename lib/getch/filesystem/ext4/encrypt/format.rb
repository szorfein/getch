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
            exec("mkfs.fat -F32 #{@dev_boot_efi}") if Helpers::efi?
            exec("mkfs.#{@fs} -F #{@luks_root}")
            exec("mkfs.#{@fs} -F #{@luks_home}") if @dev_home
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
