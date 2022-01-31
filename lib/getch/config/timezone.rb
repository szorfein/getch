# frozen_string_literal: true

require 'nito'

module Getch
  module Config
    class TimeZone
      include NiTo

      def initialize
        @log = Log.new
        @usr_share = "#{OPTIONS[:mountpoint]}/usr/share/zoneinfo"
        @etc_timezone = "#{OPTIONS[:mountpoint]}/etc/timezone"
        @etc_localtime = "#{OPTIONS[:mountpoint]}/etc/localtime"
        @rc_conf = "#{OPTIONS[:mountpoint]}/etc/rc.conf"
        @openrc = "#{OPTIONS[:mountpoint]}/etc/conf.d/keymaps"
        @timezone = OPTIONS[:timezone]
        x
      end

      protected

      def x
        @log.info "Configuring timezone to #{@timezone}...\n"
        write_rc_conf
        write_etc_timezone
        write_systemd
      end

      private

      def write_rc_conf
        return unless File.exist? @rc_conf

        echo_a @rc_conf, "TIMEZONE=\"#{@timezone}\""
      end

      def write_etc_timezone
        return unless File.exist? @openrc

        echo_a @etc_timezone, OPTIONS[:timezone]
        Getch::Chroot.new('emerge --config sys-libs/timezone-data')
      end

      def write_systemd
        return unless Helpers.systemd?

        cmd = "ln -s #{@usr_share}/#{OPTIONS[:timezone]} #{@etc_localtime}"
        Getch::Chroot.new(cmd)
      end
    end
  end
end
