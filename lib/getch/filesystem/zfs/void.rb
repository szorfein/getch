require_relative '../../helpers'

module Getch
  module FileSystem
    module Zfs
      class Void < Device
        include Helpers::Void
        attr_reader :boot_disk

        def fstab
          conf = "#{MOUNTPOINT}/etc/fstab"
          File.write(conf, "\n", mode: 'w', chmod: 0644)
          line_fstab(@dev_esp, "/efi vfat noauto,rw,relatime 0 0") if @dev_esp
          line_fstab(@dev_swap, "swap swap rw,noatime,discard 0 0") if @dev_swap
          add_line(conf, "tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0")
          zfs_zed # mountpoint for zfs
        end

        def config_dracut
          conf = "#{MOUNTPOINT}/etc/dracut.conf.d/zfs.conf"
          # dracut: value+= should be surrounding by white space
          content = [
            "hostonly=\"yes\"",
            "omit_dracutmodules+=\" btrfs lvm \"",
            ""
          ]
          File.write(conf, content.join("\n"), mode: 'w', chmod: 0644)
        end

        def kernel_cmdline_dracut
        end

        def config_grub
          conf = "#{MOUNTPOINT}/etc/default/grub"
          c="GRUB_CMDLINE_LINUX=\"root=ZFS=#{@pool_name}/ROOT/gentoo\""
          unless search(conf, c)
            File.write(conf, "#{c}\n", mode: 'a')
          end
        end

        def finish
          puts "+ Enter in your system: chroot /mnt /bin/bash"
          puts "+ Reboot with: shutdown -r now"
        end

        private

        def zfs_zed
          service_dir = "/etc/runit/runsvdir/default/"

          Helpers::mkdir("#{MOUNTPOINT}/etc/zfs/zfs-list.cache")
          Helpers::touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@boot_pool_name}") if @dev_boot
          Helpers::touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@pool_name}")
          fork { system("chroot", MOUNTPOINT, "/bin/bash", "-c", "/etc/sv/zed/run") }
          Helpers::sys("sed -Ei \"s|/mnt/gentoo/?|/|\" #{MOUNTPOINT}/etc/zfs/zfs-list.cache/*")
          command "ln -fs /etc/sv/zed #{service_dir}"
        end
      end
    end
  end
end
