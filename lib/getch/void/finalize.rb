# frozen_string_literal: true

module Getch
  module Void
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

      def finish
        puts
        puts '[*!*] Install finished [*!*]'
        puts
        #@fs.finish
        puts
      end
    end
  end
end
