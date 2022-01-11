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
          return unless Helpers.efi?
          esp = '/efi'
          dir = "#{@root_dir}/#{esp}/loader/entries/"
          datas_gentoo = [
            'title Gentoo Linux',
            'linux /vmlinuz',
            "options root=PARTUUID=#{@partuuid_root} init=#{@init} rw"
          ]
          File.write("#{dir}/gentoo.conf", datas_gentoo.join("\n"))
        end

        def grub
          return if Helpers.efi?
          file = "#{@root_dir}/etc/default/grub"
          cmdline = "GRUB_CMDLINE_LINUX=\"resume=PARTUUID=#{@partuuid_swap} root=PARTUUID=#{@partuuid_root} init=#{@init} rw slub_debug=P page_poison=1 slab_nomerge pti=on vsyscall=none spectre_v2=on spec_store_bypass_disable=seccomp iommu=force\"\n"
          File.write(file, cmdline, mode: 'a')
        end

        private

        def gen_uuid
          @partuuid_root = Helpers.partuuid(@dev_root)
          @partuuid_swap = Helpers.partuuid(@dev_swap)
          @uuid_root = `lsblk -o "UUID" #{@dev_root} | tail -1`.chomp() if @dev_root
          @uuid_esp = `lsblk -o "UUID" #{@dev_esp} | tail -1`.chomp() if @dev_esp
          @uuid_home = `lsblk -o "UUID" #{@dev_home} | tail -1`.chomp() if @dev_home
        end

        def data_fstab
          esp = @dev_esp ? "UUID=#{@uuid_esp} /efi vfat noauto,noatime 1 2" : ''
          swap = @dev_swap ? "PARTUUID=#{@partuuid_swap} none swap discard 0 0" : ''
          root = @dev_root ? "UUID=#{@uuid_root} / ext4 defaults 0 1" : ''
          home = @dev_home ? "UUID=#{@uuid_home} /home/#{@user} ext4 defaults 0 2" : ''

          [ esp, swap, root, home ]
        end
      end
    end
  end
end
