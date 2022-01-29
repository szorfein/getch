require 'nito'

module Getch
  module Config
    class PreNetwork
      include NiTo

      def initialize
        @log = Log.new
        x
      end

      protected

      def x
        @log.info "Configuring pre-network...\n"
        hostname
        copy_dns
      end

      private

      def hostname
        @log.info "Writing /etc/hostname...\t\t\t"
        echo "#{OPTIONS[:mountpoint]}/etc/hostname", 'host'
        @log.result 'Ok'
      end

      def copy_dns
        @log.info "Copying DNS from current host...\t\t"
        cp '/etc/resolv.conf', "#{OPTIONS[:mountpoint]}/etc/resolv.conf"
        echo_a "#{OPTIONS[:mountpoint]}/etc/resolv.conf", 'nameserver 127.0.0.1'
        @log.result 'Ok'
      end
    end
  end
end
