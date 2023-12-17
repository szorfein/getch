# frozen_string_literal: true

module Fstab
  # configure fstab for encrypt
  class Encrypt < Root
    def initialize(devs, options)
      super
      @luks = options[:luks_name]
    end

    def write_boot
      @boot || return

      dm = Getch::Helpers.get_dm "boot-#{@luks}"
      uuid = gen_uuid dm
      line = "UUID=#{uuid} /boot #{@fs} defaults,nosuid,noexec,nodev 1 2"
      echo_a @conf, line
    end

    def write_swap
      @swap || return

      line = "/dev/mapper/swap-#{@luks} none swap rw,noatime,discard 0 0"
      echo_a @conf, line
    end

    def write_root
      @root || return

      dm = Getch::Helpers.get_dm "root-#{@luks}"
      uuid = gen_uuid dm
      line = "UUID=#{uuid} / #{@fs} defaults 1 1"
      echo_a @conf, line
    end

    def write_home
      @home || return

      dm = Getch::Helpers.get_dm "home-#{@luks}"
      uuid = gen_uuid dm
      line = "UUID=#{uuid} /home #{@fs} defaults,nosuid,nodev 1 2"
      echo_a @conf, line
    end
  end
end
