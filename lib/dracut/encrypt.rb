# frozen_string_litteral: true

module Dracut
  class Encrypt < Root
    def generate
      host_only
      cmdline
      luks_key
    end

    protected

    def get_line
      root = get_uuid @root
      boot = get_uuid @boot
      dm_root = get_dm_uuid 'root'
      dm_swap = get_dm_uuid 'swap'
      "rd.luks.uuid=#{root} rd.luks.uuid=#{boot} root=UUID=#{dm_root} resume=UUID=#{dm_swap} rootfstype=#{@fs}"
    end

    def luks_key
      file = "#{@mountpoint}/etc/dracut.conf.d/luks_key.conf"
      echo file, 'install_items+=" /boot/volume.key /etc/crypttab "'
    end

    private

    def get_dm_uuid(name)
      dm = nil
      Dir.glob('/dev/mapper/*').each do |f|
        link = File.readlink(f)
        dm = f.delete_prefix('/dev/mapper/') if link =~ /#{name}/
      end
      dm || @log.fatal("No dev mapper found for #{name}")
      get_uuid dm
    end
  end
end
