# frozen_string_literal: true

module Fstab
  class Encrypt < Root
    def write_boot
      @boot || return

      dm = get_dm 'boot'
      uuid = gen_uuid dm
      line = "UUID=#{uuid} /boot #{@fs} noauto,rw,relatime 0 0"
      echo_a @conf, line
    end

    def write_swap
      @swap || return

      dm = get_dm 'swap'
      uuid = gen_uuid dm
      line = "UUID=#{uuid} none swap rw,noatime,discard 0 0"
      echo_a @conf, line
    end

    def write_root
      @root || return

      dm = get_dm 'root'
      uuid = gen_uuid dm
      line = "UUID=#{uuid} / #{@fs} rw,relatime 0 1"
      echo_a @conf, line
    end

    def write_home
      @home || return

      dm = get_dm 'home'
      uuid = gen_uuid dm
      line = "UUID=#{uuid} /home #{@fs} rw,relatime 0 2"
      echo_a @conf, line
    end

    private

    # We need the name of the encrypted device to get the UUID
    # e.g: ls -l /dev/mapper/root_encrypt -> ../dm-1
    def get_dm(name)
      Dir.glob('/dev/mapper/*').each do |f|
        link = File.readlink(f)
        return f.delete_prefix('/dev/mapper/') if link =~ /#{name}/
      end
      @log.fatal "No dev mapper found for #{name}"
    end
  end
end
