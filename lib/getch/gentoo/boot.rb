require 'fileutils'

module Getch
  module Gentoo
    class Boot
      def initialize(opts)
        @disk = opts.disk
        @user = opts.username
      end

      def start
        gen_fstab
        bootloader
        password
        umount
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
        puts 'Installing Bootctl...'
        # ref: https://forums.gentoo.org/viewtopic-p-8118822.html
        #exec_chroot("euse -p sys-apps/systemd -E gnuefi")
        #Helpers::emerge("sys-apps/systemd efivar", MOUNTPOINT)
        systemd = "#{MOUNTPOINT}/usr/lib/systemd"
        esp = '/boot/efi'
        FileUtils.mkdir_p "#{systemd}#{esp}", mode: 0700 if ! Dir.exist?("#{systemd}#{esp}")
        exec_chroot("bootctl --path #{esp} install")
        boot_efi = `lsblk -o "PARTUUID" /dev/#{@disk}1 | tail -1`.chomp()
        datas_gentoo = [
          'title Gentoo Linux',
          'linux /vmlinuz',
          "options root=PARTUUID=#{boot_efi} rw"
        ]
        datas_loader = [
          'default gentoo',
          'timeout 3',
          'editor 0'
        ]
        File.write("#{MOUNTPOINT}/#{esp}/loader/entries/gentoo.conf", datas_gentoo.join("\n"))
        File.write("#{MOUNTPOINT}/#{esp}/loader/loader.conf", datas_loader.join("\n"))
      end

      def grub
        puts 'Installing GRUB...'
        Helpers::emerge("sys-boot/grub:2", MOUNTPOINT)
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

      def umount
        Helpers::exec_or_die("umount -l /mnt/gentoo/dev{/shm,/pts,}")
        Helpers::exec_or_die("umount -R #{MOUNTPOINT}")
        puts "Reboot when you have done"
      end

      private

      def gen_fstab
        mount = Getch::Mount.new(@disk, @user)
        mount.gen_fstab
      end

      def exec_chroot(cmd)
        script = "chroot #{MOUNTPOINT} /bin/bash -c \"
          source /etc/profile
          #{cmd}
        \""
        Helpers::exec_or_die(script)
      end
    end
  end
end
