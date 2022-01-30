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
        @log.info "Configuring timezone to #{@timezone}..."
        write_rc_conf
        write_etc_timezone
        @log.result 'Ok'
      end

      private

      def write_rc_conf
        return unless File.exist? @rc_conf

        echo_a @rc_conf, "TIMEZONE=\"#{@timezone}\""
      end

      def write_etc_timezone
        return unless File.exist? @openrc

        echo_a @etc_timezone, OPTIONS[:timezone]
      end
    end
  end
end
