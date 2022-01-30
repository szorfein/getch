# frozen_string_literal: true

module Getch
  module Void
    class Config
      def initialize
        x
      end

      protected

      def x
        Getch::Config::Locale.new
        Getch::Config::PreNetwork.new
        Getch::Config::Keymap.new
        Getch::Config::TimeZone.new
      end

      def locale
        print ' => Updating locale system...'
        command 'xbps-reconfigure -f glibc-locales'
      end
    end
  end
end
