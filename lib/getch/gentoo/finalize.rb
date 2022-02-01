# frozen_string_literal: true

module Getch
  module Gentoo
    class Finalize
      def initialize
        x
      end

      protected

      def x
        accounts
        the_end
      end

      private

      def accounts
        account = Account.new
        account.root
        account.new_user
      end

      def the_end
        puts
        puts 'Getch has finish, before reboot, you can:'
        puts "  +  Chroot on your system with: chroot #{MOUNTPOINT} /bin/bash"
        puts '  +  Install more packages like networkmanager or emacs'
        puts
        puts 'Reboot the system when you have done !'
      end

      def chroot(cmd)
        ChrootOutput.new cmd
      end
    end
  end
end
