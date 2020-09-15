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
        puts 'Installing grub...'
        Helpers::emerge("sys-boot/grub:2", MOUNTPOINT)
        exec_chroot("grub install #{@disk}")
        exec_chroot('grub-mkconfig -o /boot/grub/grub.cfg')
      end

      def password
        puts 'Password for root'
        exec_chroot('passwd')
        if @user != nil
          puts "Creating user #{@user}"
          exec_chroot("useradd -m -G users,wheel,audio,video #{@user}")
          puts "Password for your user #{@user}"
          exec_chroot("passwd #{@user}")
        end
      end

      def umount
        Helpers::exec_or_die("mount -l /mnt/gentoo/dev{/shm,/pts,}")
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
