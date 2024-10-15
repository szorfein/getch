# frozen_string_literal: true

module Getch
  module Void
    # config before installing the system
    class PreConfig
      def initialize
        x
      end

      private

      def x
        Getch::Config::Locale.new
        Getch::Config::PreNetwork.new
      end
    end
  end
end
