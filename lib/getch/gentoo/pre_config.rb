# frozen_string_literal: true

module Getch
  module Gentoo
    class PreConfig
      def initialize
        x
      end

      private

      def x
        Getch::Config::Portage.new
        Getch::Config::Locale.new
        Getch::Config::PreNetwork.new
      end
    end
  end
end
