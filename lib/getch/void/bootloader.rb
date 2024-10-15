# frozen_string_literal: true

module Getch
  module Void
    # install grub
    class Bootloader
      def dependencies
        Helpers.efi? ? Install.new('grub-x86_64-efi') : Install.new('grub')
      end

      def install
        Config::Grub.new
        ChrootOutput.new('xbps-reconfigure -fa') # this command also start grub-mkconfig
      end
    end
  end
end
