module Getch
  module FileSystem
    module Lvm
      class Format < Getch::FileSystem::Lvm::Device
        def initialize
          super
          @state = Getch::States.new
          format
        end

        def format
          return if STATES[:format]
          exec("mkfs.fat -F32 #{@dev_esp}") if @dev_esp
          exec("mkfs.ext4 -F #{@dev_boot}") if @dev_boot
          exec("mkswap -f #{@lv_swap}")
          exec("mkfs.ext4 -F #{@lv_root}")
          exec("mkfs.ext4 -F #{@lv_home}") if @lv_home
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
