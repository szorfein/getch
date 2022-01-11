# frozen_string_literal: true

module Getch
  module FileSystem
    module Lvm
      class Config < Getch::FileSystem::Lvm::Device
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

        def systemd_boot
          return unless @efi

          esp = '/efi'
          dir = "#{@root_dir}/#{esp}/loader/entries/"
          datas_gentoo = [
            'title Gentoo Linux',
            'linux /vmlinuz',
            'initrd /initramfs',
            "options resume=#{@lv_swap} root=#{@lv_root} init=#{@init} dolvm rw"
          ]
          File.write("#{dir}/gentoo.conf", datas_gentoo.join("\n"))
        end

        def grub
          return if @efi

          file = "#{@root_dir}/etc/default/grub"
          cmdline = [ 
            "GRUB_CMDLINE_LINUX=\"resume=#{@lv_swap} root=#{@lv_root} init=#{@init} dolvm rw\""
          ]
          File.write("#{file}", cmdline.join("\n"), mode: 'a')
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
