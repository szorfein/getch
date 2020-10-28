module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Format < Getch::FileSystem::Zfs::Encrypt::Device
          def initialize
            super
            @state = Getch::States.new()
            format
          end

          def format
            return if STATES[:format]
            system("mkfs.fat -F32 #{@dev_esp}") if @dev_esp
            system("mkswap -f #{@dev_swap}")
            @state.format
          end
        end
      end
    end
  end
end
