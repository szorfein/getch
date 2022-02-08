# frozen_string_literal: true

module Fstab
  class Encrypt < Root
    def write_boot
      @boot || return

      dm = Getch::Helpers.get_dm 'boot'
      uuid = gen_uuid dm
      line = "UUID=#{uuid} /boot #{@fs} noauto,rw,relatime 0 0"
      echo_a @conf, line
    end

    def write_swap
      @swap || return

      dm = Getch::Helpers.get_dm 'swap'
      uuid = gen_uuid dm
      line = "UUID=#{uuid} none swap rw,noatime,discard 0 0"
      echo_a @conf, line
    end

    def write_root
      @root || return

      dm = Getch::Helpers.get_dm 'root'
      uuid = gen_uuid dm
      line = "UUID=#{uuid} / #{@fs} rw,relatime 0 1"
      echo_a @conf, line
    end

    def write_home
      @home || return

      dm = Getch::Helpers.get_dm 'home'
      uuid = gen_uuid dm
      line = "UUID=#{uuid} /home #{@fs} rw,relatime 0 2"
      echo_a @conf, line
    end
  end
end
