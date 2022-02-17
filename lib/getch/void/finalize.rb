# frozen_string_literal: true

module Getch
  module Void
    class Finalize
      def initialize
        x
      end

      protected

      def x
        shell
        accounts
      end

      private

      # Make the default shell /bin/bash instead of /bin/sh
      def shell
        Chroot.new('chsh -s /bin/bash')
      end

      def accounts
        account = Config::Account.new
        account.root
        account.new_user
      end
    end
  end
end
