# frozen_string_literal: true

require 'nito'

module Getch
  module Config
    class Dhcp
      include NiTo

      def initialize
        x
      end

      protected

      def x
        runit
        systemd
        openrc
      end

      private

      # https://docs.voidlinux.org/config/network/iwd.html
      def runit
        Helpers.runit? || return

        echo_a "#{OPTIONS[:mountpoint]}/etc/dhcpcd.conf", 'nohook resolv.conf'
        resolv_conf
        service = '/etc/runit/runsvdir/default/'
        Chroot.new("ln -fs /etc/sv/dhcpcd #{service}")
      end

      def systemd
        Helpers.systemd? || return

        systemd_ethernet
        systemd_wireless
        systemd_resolve
        Chroot.new('systemctl enable systemd-networkd')
        Chroot.new('systemctl enable systemd-resolved')
      end

      def openrc
        Helpers.openrc? || return

        echo_a "#{OPTIONS[:mountpoint]}/etc/dhcpcd.conf", 'nohook resolv.conf'
        resolv_conf
        Chroot.new('rc-update add dhcpcd default')
      end

      # https://www.dnsknowledge.com/tutorials/how-to-setup-quad9-dns-on-a-linux/
      def resolv_conf
        conf = "#{OPTIONS[:mountpoint]}/etc/resolv.conf"
        content = <<~CONF
        nameserver 9.9.9.9
        nameserver 2620:fe::fe
        options rotate
        CONF
        File.write conf, "#{content}\n"
      end

      def systemd_ethernet
        conf = "#{OPTIONS[:mountpoint]}/etc/systemd/network/20-ethernet.network"
        content = <<~NETWORK
        [Match]
        Name=en*
        Name=eth*
        [Network]
        DHCP=yes
        IPv6PrivacyExtensions=yes
        [DHCP]
        RouteMetric=512
        NETWORK
        File.write(conf, "#{content}\n")
      end

      def systemd_wireless
        conf = "#{OPTIONS[:mountpoint]}/etc/systemd/network/20-wireless.network"
        content = <<~NETWORK
        [Match]
        Name=wl*
        [Network]
        DHCP=yes
        IPv6PrivacyExtensions=yes
        [DHCP]
        RouteMetric=1024
        NETWORK
        File.write conf, "#{content}\n"
      end

      def systemd_resolve
        mkdir "#{OPTIONS[:mountpoint]}/etc/systemd/resolved.conf.d"
        conf = "#{OPTIONS[:mountpoint]}/etc/systemd/resolved.conf.d/dns_tls.conf"
        content = <<~CONF
        [Resolve]
        DNS=9.9.9.9#dns.quad9.net
        DNSOverTLS=yes
        CONF
        File.write conf, "#{content}\n"
      end
    end
  end
end
