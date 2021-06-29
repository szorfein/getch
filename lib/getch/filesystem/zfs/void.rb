require_relative '../../helpers'

module Getch
  module FileSystem
    module Zfs
      class Void < Device
        include Helpers::Void
        attr_reader :boot_disk

        def initialize
          super
          hostid
          zfs_zed # mountpoint for zfs
        end

        # Fstab contain:
        # > /efi noauto
        # > swap
        # > /boot zfs-legacy
        # > /tmp
        def fstab
          conf = "#{MOUNTPOINT}/etc/fstab"
          File.write(conf, "\n", mode: 'w', chmod: 0644)
          line_fstab(@dev_esp, "/efi vfat noauto,rw,relatime 0 0") if @dev_esp
          line_fstab(@dev_swap, "swap swap rw,noatime,discard 0 0") if @dev_swap
          #add_line(conf, "#{@boot_pool_name}/BOOT/#{@n} /boot zfs defaults 0 0") if @dev_boot
          add_line(conf, "tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0")
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
          #command "zfs set mountpoint=legacy #{@boot_pool_name}/BOOT/#{@n}"
        end

        def config_grub
          grub_cmdline("root=zfs:#{@pool_name}/ROOT/#{@n}", "zfs_force=1")
        end

        def finish
          zed_update_path
          puts "+ Enter in your system: chroot /mnt /bin/bash"
          puts "+ Reboot with: shutdown -r now"
        end

        private

        def zfs_zed
          service_dir = "/etc/runit/runsvdir/default/"

          Helpers::mkdir("#{MOUNTPOINT}/etc/zfs/zfs-list.cache")
          Helpers::touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@boot_pool_name}") if @dev_boot
          Helpers::touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@pool_name}")
          fork { command "/etc/sv/zed/run" }
          command "ln -fs /etc/sv/zed #{service_dir}"
        end

        def zed_update_path
          Dir.glob("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/*").each { |f|
            if !system("sed", "-Ei", "s|#{MOUNTPOINT}/?|/|", f)
              raise "System exec sed"
            end
          }
        end

        def hostid
          command "zgenhostid $(hostid)"
        end
      end
    end
  end
end
