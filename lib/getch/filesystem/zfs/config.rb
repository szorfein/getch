# frozen_string_literal: true

module Getch
  module FileSystem
    module Zfs
      class Config < Device
        def initialize
          super
          gen_uuid
          @root_dir = MOUNTPOINT
          @init = '/usr/lib/systemd/systemd'
        end

        def fstab
          file = "#{@root_dir}/etc/fstab"
          datas = data_fstab
          File.write(file, datas.join("\n"))
        end

        # See https://wiki.gentoo.org/wiki/ZFS#ZFS_root
        def cmdline
          line = "resume=UUID=#{@uuid_swap} root=ZFS:#{@pool_name}/ROOT/#{@n} init=#{@init} zfs.force=1 zfs.zfs_arc_max=536870912\""
          Getch::Bask.new(line).cmdline
        end

        private

        def gen_uuid
          @uuid_swap = `lsblk -o "UUID" #{@dev_swap} | tail -1`.chomp()
          @uuid_esp = `lsblk -o "UUID" #{@dev_esp} | tail -1`.chomp() if @dev_esp
        end

        def data_fstab
          efi = @dev_esp ? "UUID=#{@uuid_esp} /efi vfat noauto,noatime 1 2" : ''
          swap = @dev_swap ? "UUID=#{@uuid_swap} none swap discard 0 0" : ''

          [ efi, swap ]
        end
      end
    end
  end
end
