
module Fstab
  # Hybrid for Lvm + Encryption
  class Hybrid < Encrypt
    def initialize(devs, options)
      super
      @vg = options[:vg_name] ||= 'vg0'
      @luks = options[:luks_name]
    end

    # The swap UUID based on the lvm volume /dev/vg/swap
    def write_swap
      # The both use /etc/crypttab
      if Getch::Helpers.runit? || Getch::Helpers.systemd?
        echo_a @conf, "/dev/mapper/swap-#{@luks} none swap sw 0 0"
      else
        dm = Getch::Helpers.get_dm "#{@vg}-swap"
        uuid = Getch::Helpers.uuid dm
        line = "UUID=#{uuid} none swap sw 0 0"
        echo_a @conf, line
      end
    end

    def write_root
      line = "/dev/#{@vg}/root / #{@fs} rw,relatime 0 1"
      echo_a @conf, line
    end

    def write_home
      line = "/dev/#{@vg}/home /home #{@fs} rw,relatime 0 2"
      echo_a @conf, line
    end
  end
end
