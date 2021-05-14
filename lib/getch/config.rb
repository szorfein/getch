module Getch
  class Config
    def initialize
      @systemd_net_dir = "#{MOUNTPOINT}/etc/systemd"
    end

    def network
      ethernet
      wifi
      resolved
      Getch::Chroot.new('systemctl enable systemd-networkd').run!
      Getch::Chroot.new('systemctl enable systemd-resolved').run!
    end

    private

    def ethernet
      conf = "#{@systemd_net_dir}/network/20-ethernet.network"
      datas = [
        "[Match]",
        "Name=en*",
        "Name=eth*",
        "[Network]",
        "DHCP=yes",
        "IPv6PrivacyExtensions=yes",
        "[DHCP]",
        "RouteMetric=512"
      ]
      File.write(conf, datas.join("\n"), mode: 'w')
    end

    def wifi
      conf = "#{@systemd_net_dir}/network/20-wireless.network"
      datas = [
        "[Match]",
        "Name=wlp*",
        "Name=wlan*",
        "[Network]",
        "DHCP=yes",
        "IPv6PrivacyExtensions=yes",
        "[DHCP]",
        "RouteMetric=1024",
      ]
      File.write(conf, datas.join("\n"), mode: 'w')
    end

    def resolved
      conf = "#{@systemd_net_dir}/resolved.conf.d/dns_over_tls.conf"
      datas = [
        "[Resolve]",
        "DNS=9.9.9.9#dns.quad9.net",
        "DNSOverTLS=yes",
      ]
      Helpers::create_dir("#{@systemd_net_dir}/resolved.conf.d")
      File.write(conf, datas.join("\n"), mode: 'w')

      use = Getch::Gentoo::Use.new("sys-apps/systemd")
      use.add('dns-over-tls')
    end
  end
end
