module Getch
  module FileSystem
    module Zfs
      class Deps < Device
        def make
          unstable_zfs
          install_deps
          zfs_mountpoint
          auto_module_rebuild
          hostid
          options_make
          Getch::Make.new("genkernel --kernel-config=/usr/src/linux/.config all").run!
          zed_update_path
        end

        private

        def unstable_zfs
          conf = "#{MOUNTPOINT}/etc/portage/package.accept_keywords/zfs"
          data = [
            "sys-fs/zfs-kmod",
            "sys-fs/zfs"
          ]
          File.write(conf, data.join("\n"), mode: "w")
        end

        def install_deps
          Getch::Bask.new('-a zfs').run!
          Getch::Make.new("make modules_prepare").run!
          Getch::Make.new("make -j$(nproc)").run!
          Getch::Emerge.new('genkernel sys-fs/zfs').pkg!
        end

        # See: https://wiki.archlinux.org/index.php/ZFS#Using_zfs-mount-generator
        def zfs_mountpoint
          Helpers.mkdir("#{MOUNTPOINT}/etc/zfs/zfs-list.cache")
          Helpers.touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@boot_pool_name}") if @dev_boot
          Helpers.touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@pool_name}")
          exec("ln -fs /usr/libexec/zfs/zed.d/history_event-zfs-list-cacher.sh /etc/zfs/zed.d/")
          exec("systemctl start zfs-zed.service")
          exec("systemctl enable zfs-zed.service")
          exec("systemctl enable zfs.target")
        end

        def zed_update_path
          Dir.glob("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/*").each { |f|
            if !system("sed", "-Ei", "s|#{MOUNTPOINT}/?|/|", f)
              raise "system exec sed"
            end
          }
        end

        def auto_module_rebuild
          g_dir="#{MOUNTPOINT}/etc/portage/env/sys-kernel"
          Helpers.mkdir(g_dir)
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

        def hostid
          exec "zgenhostid $(hostid)"
        end

        def options_make
          bootloader = Helpers.efi? ? 'BOOTLOADER="no"' : 'BOOTLOADER="grub2"'
          datas = [
            '',
            bootloader,
            'INSTALL="yes"',
            'MENUCONFIG="no"',
            'CLEAN="yes"',
            'SAVE_CONFIG="yes"',
            'MOUNTBOOT="no"',
            'MRPROPER="no"',
            'ZFS="yes"',
            'MODULEREBUILD="yes"'
          ]
          file = "#{MOUNTPOINT}/etc/genkernel.conf"
          File.write(file, datas.join("\n"), mode: 'a')
        end

        def exec(cmd)
          Getch::Chroot.new(cmd).run!
        end
      end
    end
  end
end
