require 'fileutils'

module Getch
  module Gentoo
    class Boot
      def initialize(opts)
        @disk = opts.disk
        @user = opts.username
        @config = Getch.class_fs::Config.new()
      end

      def start
        @config.fstab
        bootloader
        password
        the_end
      end

      def bootloader
        if Helpers::efi?
          bootctl
        else
          grub
        end
      end

      # bootctl is alrealy installed with the stage3-amd64-systemd
      def bootctl
        bootctl_dep
        puts "Configuring systemd-boot."
        # ref: https://forums.gentoo.org/viewtopic-p-8118822.html
        esp = '/boot/efi'
        exec_chroot("bootctl --path #{esp} install")
        datas_loader = [
          'default gentoo',
          'timeout 3',
          'editor 0'
        ]
        @config.systemd_boot
        File.write("#{MOUNTPOINT}/#{esp}/loader/loader.conf", datas_loader.join("\n"))

        FileUtils.cp("#{MOUNTPOINT}/usr/src/linux/arch/x86/boot/bzImage", "#{MOUNTPOINT}/#{esp}/vmlinuz", preserve: true)

        initramfs = Dir.glob("#{MOUNTPOINT}/boot/initramfs-*.img")
        FileUtils.cp("#{initramfs[0]}", "#{MOUNTPOINT}/#{esp}/initramfs", preserve: true) if initramfs != []

        exec_chroot("bootctl --path #{esp} update")
      end

      def bootctl_dep
        puts 'Installing systemd-boot...'
        exec_chroot("euse -p sys-apps/systemd -E gnuefi")
        Getch::Emerge.new("sys-apps/systemd efivar").pkg!
      end

      def grub
        puts 'Installing GRUB...'
        Getch::Emerge.new("sys-boot/grub:2").pkg!
        @config.grub
        exec_chroot("grub-install /dev/#{@disk}")
        exec_chroot('grub-mkconfig -o /boot/grub/grub.cfg')
      end

      def password
        puts 'Password for root'
        cmd = "chroot #{MOUNTPOINT} /bin/bash -c \"source /etc/profile && passwd\""
        system(cmd)
        if @user != nil
          puts "Creating user #{@user}"
          exec_chroot("useradd -m -G users,wheel,audio,video #{@user}")
          puts "Password for your user #{@user}"
          cmd = "chroot #{MOUNTPOINT} /bin/bash -c \"source /etc/profile && passwd #{@user}\""
          system(cmd)
        end
      end

      private

      def the_end
        #Helpers::exec_or_die("umount -l /mnt/gentoo/dev{/shm,/pts,}")
        #Helpers::exec_or_die("umount -R #{MOUNTPOINT}")
        puts
        puts "getch has finish, before reboot, you can:"
        puts "  +  Chroot on your system with: chroot #{MOUNTPOINT} /bin/bash"
        puts "  +  Install more packages like networkmanager or emacs"
        puts
        puts "  +  Add more modules for your kernel (graphic, wifi card) and recompile it with:"
        puts "  genkernel --kernel-config=/usr/src/linux/.config all  "
        puts
        puts "Reboot the system when you have done !"
      end

      def exec_chroot(cmd)
        script = "chroot #{MOUNTPOINT} /bin/bash -c \"
          source /etc/profile
          #{cmd}
        \""
        Getch::Command.new(script).run!
      end
    end
  end
end
