# frozen_string_literal: true

module Getch
  module Config
    class Void
      include Helpers::Void

      def initialize
        @service_dir = '/etc/runit/runsvdir/default/'
      end

      # Enable dhcpcd service
      def ethernet
        command "ln -fs /etc/sv/dhcpcd #{@service_dir}"
      end

      # with Quad9
      # https://www.dnsknowledge.com/tutorials/how-to-setup-quad9-dns-on-a-linux/
      def dns
        conf = "#{MOUNTPOINT}/etc/resolv.conf"
        content = [
          'nameserver 9.9.9.9',
          'nameserver 2620:fe::fe',
          'options rotate',
        ]
        File.write(conf, content.join("\n"), mode: 'w', chmod: 0644)
      end

      # https://docs.voidlinux.org/config/network/iwd.html
      def wifi
        conf = "#{MOUNTPOINT}/etc/iwd/main.conf"
        content = [
          '[General]',
          'UseDefaultInterface=true',
        ]
        File.write(conf, content.join("\n"), mode: 'a', chmod: 0644)
        # Enabling dbus and iwd
        command "ln -fs /etc/sv/dbus #{@service_dir}"
        command "ln -fs /etc/sv/iwd #{@service_dir}"
      end

      def shell
        command 'chsh -s /bin/bash'
      end
    end
  end
end
