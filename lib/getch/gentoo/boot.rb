module Getch
  module Gentoo
    class Boot
      def initialize(opts)
        @disk = opts.disk
        @user = opts.username
      end

      def start
        gen_fstab
        grub
        password
        umount
      end

      def grub
        return if Helpers::efi?
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
        Helpers::exec_or_die("umount -R #{MOUNTPONT}")
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
