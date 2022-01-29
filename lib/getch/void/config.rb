# frozen_string_literal: true

module Getch
  module Void
    class Config
      include Helpers::Void

      def initialize
        @log = Getch::Log.new
        x
      end

      def x
        Getch::Config::Locale.new
        Getch::Config::PreNetwork.new
        Getch::Config::Keymap.new
      end

      def system
        print ' => Updating configs system...'
        control_options
        rc = "#{MOUNTPOINT}/etc/rc.conf"
        add_line(rc, "TIMEZONE=\"#{OPTIONS[:zoneinfo]}\"") unless search(rc, /^TIMEZONE/)
        puts "\s[OK]"
      end

      def locale
        print ' => Updating locale system...'
        command 'xbps-reconfigure -f glibc-locales'
      end

      private

      def control_options
        search_zone(OPTIONS[:zoneinfo])
      end

      def search_zone(zone)
        unless File.exist? "#{MOUNTPOINT}/usr/share/zoneinfo/#{zone}"
          raise ArgumentError, "Zoneinfo #{zone} doesn\'t exist."
        end
      end
    end
  end
end
