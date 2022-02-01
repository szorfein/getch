# frozen_string_literal: true

module Getch
  module Void
    class Bootloader
      def initialize
        x
      end

      protected

      def x
        dependencies
        setup
        initramfs
      end

      private

      def dependencies
        Helpers.efi? ? Install.new('grub-x86_64-efi') :
          Install.new('grub')
      end

      def setup
        Config::Grub.new
      end

      def initramfs
        ChrootOutput.new('xbps-reconfigure -fa') # this command also start grub-mkconfig
      end
    end
  end
end
