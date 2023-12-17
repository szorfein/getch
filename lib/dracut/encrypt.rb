# frozen_string_literal: true

module Dracut
  # configure dracut for encypted system
  class Encrypt < Root
    def initialize(devs, options)
      @luks = options[:luks_name]
      super
    end

    def generate
      host_only
      cmdline
      luks_key
    end

    protected

    def get_line
      root = Getch::Helpers.uuid @root
      dm_root = get_dm_uuid "root-#{@luks}"
      "rd.luks.uuid=#{root} root=UUID=#{dm_root} rootfstype=#{@fs}"
    end

    def luks_key
      file = "#{@mountpoint}/etc/dracut.conf.d/luks_key.conf"
      echo file, 'install_items+=" /boot/root.key /etc/crypttab "'
    end

    private

    def get_dm_uuid(name)
      dm = Getch::Helpers.get_dm name
      Getch::Helpers.uuid dm
    end
  end
end
