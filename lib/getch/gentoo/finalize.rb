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
      end

      private

      def accounts
        account = Account.new
        account.root
        account.new_user
      end
    end
  end
end
