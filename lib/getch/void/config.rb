# frozen_string_literal: true

require 'fileutils'

module Getch
  module Void
    class Config
      include Helpers::Void

      def initialize
        @log = Getch::Log.new
        @network_dir = "#{MOUNTPOINT}/etc"
        x
      end

      def x
        Getch::Config::Locale.new
        Getch::Config::PreNetwork.new
      end

      def system
        print ' => Updating configs system...'
        control_options
        rc = "#{MOUNTPOINT}/etc/rc.conf"
        add_line(rc, 'HARDWARECLOCK="UTC"') unless search(rc, /^HARDWARECLOCK/)
        add_line(rc, "KEYMAP=\"#{OPTIONS[:keymap]}\"") unless search(rc, /^KEYMAP/)
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
        search_key(OPTIONS[:keymap])
      end

      def search_key(keys)
        @keymap = nil
        Dir.glob("#{MOUNTPOINT}/usr/share/kbd/keymaps/**/#{keys}.map.gz") { |f|
          @keymap = f
        }
        raise ArgumentError, "No keymap #{@keymap} found" unless @keymap
      end

      def search_zone(zone)
        unless File.exist? "#{MOUNTPOINT}/usr/share/zoneinfo/#{zone}"
          raise ArgumentError, "Zoneinfo #{zone} doesn\'t exist."
        end
      end
    end
  end
end
