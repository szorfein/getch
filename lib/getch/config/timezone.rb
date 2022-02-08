# frozen_string_literal: true

require 'nito'

module Getch
  module Config
    class TimeZone
      include NiTo

      def initialize
        @log = Log.new
        @etc_timezone = "#{OPTIONS[:mountpoint]}/etc/timezone"
        @rc_conf = "#{OPTIONS[:mountpoint]}/etc/rc.conf"
        @openrc = "#{OPTIONS[:mountpoint]}/etc/conf.d/keymaps"
        @timezone = OPTIONS[:timezone]
        x
      end

      protected

      def x
        @log.info "Configuring timezone to #{@timezone}...\n"
        for_runit
        for_openrc
        for_systemd
      end

      private

      def for_runit
        return unless Helpers.runit?

        echo_a @rc_conf, "TIMEZONE=\"#{@timezone}\""
      end

      def for_openrc
        return unless Helpers.openrc?

        echo_a @etc_timezone, OPTIONS[:timezone]
        Getch::Chroot.new('emerge --config sys-libs/timezone-data')
      end

      def for_systemd
        return unless Helpers.systemd?

        src = "/usr/share/zoneinfo/#{OPTIONS[:timezone]}"
        dest = "/etc/localtime"
        Getch::Chroot.new('ln', '-sf', src, dest)
      end
    end
  end
end
