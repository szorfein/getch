module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Format < Getch::FileSystem::Ext4::Encrypt::Device
          def initialize
            super
            @state = Getch::States.new()
            format
          end

          def format
            return if STATES[:format]
            exec("mkfs.fat -F32 #{@dev_esp}") if @dev_esp
            exec("mkfs.ext4 -F #{@luks_root}")
            exec("mkswap -f #{@dev_swap}")
            exec("mkfs.ext4 -F #{@luks_home}") if @dev_home
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
