# frozen_string_literal: true

module Getch
  module FileSystem
    module Lvm
      class Void < Device
        include Helpers::Void

        attr_reader :boot_disk

        def config_dracut
          conf = "#{MOUNTPOINT}/etc/dracut.conf.d/lvm.conf"
          # dracut: value+= should be surrounding by white space
          content = [
            "hostonly=\"yes\"",
            "omit_dracutmodules+=\" btrfs \"",
            ""
          ]
          File.write(conf, content.join("\n"), mode: 'w', chmod: 0644)
        end

        def kernel_cmdline_dracut
          conf = "#{MOUNTPOINT}/etc/dracut.conf.d/cmdline.conf"
          c="kernel_cmdline=\"rd.lvm.vg=#{@vg} rootflags=rw,relatime\""
          File.write(conf, "#{c}\n", mode: 'w', chmod: 0644)
        end

        def finish
          puts '+ Enter in your system: chroot /mnt /bin/bash'
          puts '+ Reboot with: shutdown -r now'
        end
      end
    end
  end
end
