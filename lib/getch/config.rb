module Getch
  class Config
    def initialize
      @systemd_net_dir = "#{MOUNTPOINT}/etc/systemd/network"
    end

    def network
      ethernet
      wifi
    end

    private

    def ethernet
      conf = "#{@systemd_net_dir}/20-ethernet.network"
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
      conf = "#{@systemd_net_dir}/20-wireless.network"
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
  end
end
