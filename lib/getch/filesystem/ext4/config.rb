module Getch
  module FileSystem
    module Ext4
      class Config < Getch::FileSystem::Ext4::Device
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
          return if ! Helpers::efi? 
          esp = '/boot/efi'
          dir = "#{@root_dir}/#{esp}/loader/entries/"
          datas_gentoo = [
            'title Gentoo Linux',
            'linux /vmlinuz',
            "options root=UUID=#{uuid_root} init=#{@init} rw"
          ]
          File.write("#{dir}/gentoo.conf", datas_gentoo.join("\n"))
        end

        def grub
          return if Helpers::efi?
          file = "#{@root_dir}/etc/default/grub"
          cmdline = "GRUB_CMDLINE_LINUX_DEFAULT=\"resume=UUID=#{@uuid_swap} root=UUID=#{@uuid_root} init=#{@init} rw\""
          File.write("#{file}", cmdline.join("\n"), mode: 'a')
        end

        private

        def gen_uuid
          @uuid_swap = `lsblk -o "UUID" #{@dev_swap} | tail -1`.chomp() if @dev_swap
          @uuid_root = `lsblk -o "UUID" #{@dev_root} | tail -1`.chomp() if @dev_root
          @uuid_boot = `lsblk -o "UUID" #{@dev_boot} | tail -1`.chomp() if @dev_boot
          @uuid_boot_efi = `lsblk -o "UUID" #{@dev_boot_efi} | tail -1`.chomp() if @dev_boot_efi
          @uuid_home = `lsblk -o "UUID" #{@dev_home} | tail -1`.chomp() if @dev_home
        end

        def data_fstab
          boot_efi = @dev_boot_efi ? "UUID=#{@uuid_boot_efi} /boot/efi vfat noauto,defaults  0 2" : ''
          swap = @dev_swap ? "UUID=#{@uuid_swap} none swap discard 0 0" : ''
          root = @dev_root ? "UUID=#{@uuid_root} / ext4 defaults 0 1" : ''
          home = @dev_home ? "UUID=#{@uuid_home} /home/#{@user} ext4 defaults 0 2" : ''

          return [ boot_efi, swap, root, home ]
        end
      end
    end
  end
end