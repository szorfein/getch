require_relative '../helpers'

module Getch
  module Config
    class Void
      include Helpers::Void

      def initialize
      end

      # Enable dhcpcd service
      def ethernet
        command "ln -s /etc/sv/dhcpcd /var/service/"
      end

      # with Quad9
      # https://www.dnsknowledge.com/tutorials/how-to-setup-quad9-dns-on-a-linux/
      def dns
        conf = "#{MOUNTPOINT}/etc/resolv.conf"
        content = [
          "nameserver 9.9.9.9",
          "nameserver 2620:fe::fe",
          "options rotate",
          "",
        ]
        File.write(conf, content.join("\n"), mode: 'w', chmod: 0644)
      end

      # https://docs.voidlinux.org/config/network/iwd.html
      def wifi
        conf = "#{MOUNTPOINT}/etc/iwd/main.conf"
        content = [
          "[General]",
          "UseDefaultInterface=true",
          "",
        ]
        File.write(conf, content.join("\n"), mode: 'a', chmod: 0644)
        command "ln -s /etc/sv/iwd /var/service/"
      end
    end
  end
end
