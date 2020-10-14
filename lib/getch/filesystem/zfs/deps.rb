module Getch
  module FileSystem
    module Zfs
      class Deps
        def initialize
          if Helpers::efi?
            install_efi
          else
            install_bios
          end
          install_deps
          zfs_mountpoint
          auto_module_rebuild
        end

        def auto_module_rebuild
          g_dir="#{MOUNTPOINT}/etc/portage/env/sys-kernel"
          Helpers::mkdir(g_dir)
          # See https://wiki.gentoo.org/wiki/Kernel/Upgrade#Automated_build_and_installation
          content=<<EOF
post_pkg_postinst() {
  # BUG: reinstalls of a source will cause errors
  CURRENT_KV=$(uname -r)
  # Check to see if genkernel has been run previously for the running kernel and use that config
  if [[ -f "${EROOT}/etc/kernels/kernel-config-${CURRENT_KV}" ]] ; then
    genkernel --kernel-config="${EROOT}/etc/kernels/kernel-config-${CURRENT_KV}" all
  elif [[ -f "${EROOT}/usr/src/linux-${CURRENT_KV}/.config" ]] ; then # Use latest kernel config from current kernel
    genkernel --kernel-config="${EROOT}/usr/src/linux-${CURRENT_KV}/.config" all
  else # No valid configs known
    genkernel all
  fi
}
EOF
          File.write("#{g_dir}/gentoo-sources", content)
        end

        def zfs_mountpoint
          Helpers::mkdir("#{MOUNTPOINT}/etc/zfs/zfs-list.cache")
          Helpers::touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/bpool")
          Helpers::touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/rpool")
          Helpers::run_chroot("ln -s /usr/libexec/zfs/zed.d/history_event-zfs-list-cacher.sh /etc/zfs/zed.d/", MOUNTPOINT)
          Helpers::run_chroot("zed", MOUNTPOINT)
          system("sed -Ei \"s|/mnt/?|/|\" #{MOUNTPOINT}/etc/zfs/zfs-list.cache/*")
          unless $?.success?
            raise "Error with sed"
          end
        end

        def make
          hostid
          options_make
          if ! Helpers::grep?("#{MOUNTPOINT}/etc/genkernel.conf", /ZFS="yes"/)
            raise "Error by adding new options to genkernel.conf"
          end
          Getch::Make.new("genkernel --kernel-config=/usr/src/linux/.config all").run!
          Getch::Emerge.new("@module-rebuild")
        end

        private
        def hostid
          hostid_value=`hostid`.chomp
          File.write("#{MOUNTPOINT}/etc/hostid", hostid_value, mode: 'w')
        end

        def options_make
          grub = Helpers::efi? ? 'BOOTLOADER="no"' : 'BOOTLOADER="grub2"'
          datas = [
            '',
            grub,
            'INSTALL="yes"',
            'MENUCONFIG="no"',
            'CLEAN="yes"',
            'SAVE_CONFIG="yes"',
            'MOUNTBOOT="no"',
            'MRPROPER="no"',
            'ZFS="yes"',
          ]
          file = "#{MOUNTPOINT}/etc/genkernel.conf"
          File.write(file, datas.join("\n"), mode: 'a')
        end

        def install_efi
        end

        def install_bios
        end

        def install_deps
          exec("euse -E libzfs") if ! Helpers::grep?("#{MOUNTPOINT}/etc/portage/make.conf", /libzfs/)
          exec("euse -E rootfs") if ! Helpers::grep?("#{MOUNTPOINT}/etc/portage/make.conf", /rootfs/)
          Getch::Garden.new('-a zfs').run!
          Getch::Make.new("make modules_prepare").run!
          Getch::Make.new("make -j$(nproc)").run!
          Getch::Emerge.new('genkernel sys-fs/zfs').pkg!
        end

        def exec(cmd)
          Helpers::run_chroot(cmd, MOUNTPOINT)
        end
      end
    end
  end
end
