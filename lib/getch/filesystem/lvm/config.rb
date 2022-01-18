# frozen_string_literal: true

module Getch
  module FileSystem
    module Lvm
      class Config < Getch::FileSystem::Lvm::Device
        def initialize
          super
          gen_uuid
          @init = '/usr/lib/systemd/systemd'
        end

        def fstab
          file = "#{MOUNTPOINT}/etc/fstab"
          datas = data_fstab
          File.write(file, datas.join("\n"))
        end

        def cmdline
          conf = "#{MOUNTPOINT}/etc/dracut.conf.d/cmdline.conf"
          line = "resume=#{@lv_swap} rd.lvm.vg=#{@vg} init=#{@init}"
          File.write conf, "kernel_cmdline=\"#{line}\"\n"
        end

        private

        def gen_uuid
          @uuid_boot = `lsblk -o "UUID" #{@dev_boot} | tail -1`.chomp() if @dev_boot
          @uuid_esp = `lsblk -o "UUID" #{@dev_esp} | tail -1`.chomp() if @dev_esp
        end

        def data_fstab
          efi = @dev_esp ? "UUID=#{@uuid_esp} /efi vfat noauto,noatime 1 2" : ''
          boot = @dev_boot ? "UUID=#{@uuid_boot} /boot ext4 noauto,noatime 1 2" : ''
          swap = "#{@lv_swap} none swap discard 0 0"
          root = "#{@lv_root} / ext4 defaults 0 1"
          home = @lv_home ? "#{@lv_home} /home/#{@user} ext4 defaults 0 2" : ''

          [ efi, boot, swap, root, home ]
        end
      end
    end
  end
end
