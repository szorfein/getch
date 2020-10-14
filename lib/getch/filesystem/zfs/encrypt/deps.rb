module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Deps < Getch::FileSystem::Zfs::Encrypt::Device
          def initialize
            super
            install_deps
            zfs_mountpoint
            auto_module_rebuild
          end

          def make
            hostid
            options_make
            Getch::Make.new("genkernel --kernel-config=/usr/src/linux/.config all").run!
          end

          private
          def install_deps
            exec("euse -E libzfs") if ! Helpers::grep?("#{MOUNTPOINT}/etc/portage/make.conf", /libzfs/)
            exec("euse -E rootfs") if ! Helpers::grep?("#{MOUNTPOINT}/etc/portage/make.conf", /rootfs/)
            Getch::Garden.new('-a zfs').run!
            Getch::Make.new("make modules_prepare").run!
            Getch::Make.new("make -j$(nproc)").run!
            Getch::Emerge.new('genkernel sys-fs/zfs').pkg!
          end

          # See: https://wiki.archlinux.org/index.php/ZFS#Using_zfs-mount-generator
          def zfs_mountpoint
            Helpers::mkdir("#{MOUNTPOINT}/etc/zfs/zfs-list.cache")
            Helpers::touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@boot_pool_name}") if @dev_boot
            Helpers::touch("#{MOUNTPOINT}/etc/zfs/zfs-list.cache/#{@pool_name}")
            exec("ln -fs /usr/libexec/zfs/zed.d/history_event-zfs-list-cacher.sh /etc/zfs/zed.d/")
            exec("systemctl start zfs-zed.service")
            Helpers::sys("sed -Ei \"s|/mnt/?|/|\" #{MOUNTPOINT}/etc/zfs/zfs-list.cache/*")
            exec("systemctl enable zfs-zed.service")
            exec("systemctl enable zfs.target")
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

          def hostid
            hostid_value=`hostid`.chomp
            File.write("#{MOUNTPOINT}/etc/hostid", hostid_value, mode: 'w')
          end

          def options_make
            bootloader = Helpers::efi? ? 'BOOTLOADER="no"' : 'BOOTLOADER="grub2"'
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
end
