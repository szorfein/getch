# frozen_string_literal: true

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Config < Device
          def initialize
            super
            gen_uuid
            @init = '/usr/lib/systemd/systemd'
            crypttab
          end

          def fstab
            file = "#{MOUNTPOINT}/etc/fstab"
            datas = data_fstab
            File.write(file, datas.join("\n"))
          end

          def cmdline
            src = "#{MOUNTPOINT}/etc/dracut.conf.d/cmdline.conf"
            line = "kernel_cmdline=\"root=zfs:#{@pool_name}/ROOT/#{@n} init=#{@init} rd.vconsole.keymap=#{Getch::OPTIONS[:keymap]} zfs.force=1 zfs.zfs_arc_max=536870912\""
            Helpers.echo src, line
          end

          def crypttab
            datas = [
              "cryptswap PARTUUID=#{@partuuid_swap} /dev/urandom swap,discard,cipher=aes-xts-plain64:sha256,size=512"
            ]
            File.write("#{MOUNTPOINT}/etc/crypttab", datas.join("\n"))
          end

          private

          def gen_uuid
            @partuuid_swap = Helpers.partuuid(@dev_swap)
            @uuid_esp = `lsblk -o "UUID" #{@dev_esp} | tail -1`.chomp() if @dev_esp
          end

          def data_fstab
            boot_efi = @dev_esp ? "UUID=#{@uuid_esp} /efi vfat noauto,noatime 1 2" : ''
            swap = @dev_swap ? '/dev/mapper/cryptswap none swap sw 0 0' : ''

            [ boot_efi, swap ]
          end
        end
      end
    end
  end
end
