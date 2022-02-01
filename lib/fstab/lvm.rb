# frozen_string_litteral: true

module Fstab
  class Lvm < Root
    def initialize(devs, options)
      super
      @vg = options[:vg_name]
    end

    def write_swap
      line = "/dev/#{@vg}/swap swap swap rw,noatime,discard 0 0"
      echo_a @conf, line
    end

    def write_root
      line = "/dev/#{@vg}/root #{@fs} rw,relatime 0 1"
      echo_a @conf, line
    end

    def write_home
      line = "/dev/#{@vg}/home #{@fs} rw,relatime 0 2"
      echo_a @conf, line
    end
  end
end
