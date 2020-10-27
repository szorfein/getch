module Getch
  module FileSystem
    module Lvm
      class Partition < Getch::FileSystem::Lvm::Device
        def initialize
          super
          @state = Getch::States.new()
          @partition = Getch::FileSystem::Partition.new
          @clean = Getch::FileSystem::Clean
          run_partition
        end

        def run_partition
          return if STATES[:partition ]
          @clean.old_vg(@dev_root, @vg)
          @clean.struct(@disk)
          @clean.hdd(@disk)
          partition
          lvm
          @state.partition
        end

        private

        def partition
          if Helpers::efi?
            @partition.efi(@disk)
            exec("sgdisk -n2:0:+0 -t2:8e00 /dev/#{@disk}")
          else
            @partition.gpt(@disk)
            @partition.boot(@disk)
            exec("sgdisk -n3:0:+0 -t3:8e00 /dev/#{@disk}")
          end
        end

        def lvm
          mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'
          exec("pvcreate -f #{@dev_root}")
          exec("vgcreate -f #{@vg} #{@dev_root}")
          # Wipe old signature: https://github.com/chef-cookbooks/lvm/issues/45
          exec("lvcreate -y -Wy -Zy -L #{mem} -n swap #{@vg}")

          if @user
            exec("lvcreate -y -Wy -Zy -L 18G -n root #{@vg}")
            exec("lvcreate -y -Wy -Zy -l 100%FREE -n home #{@vg}")
          else
            exec("lvcreate -y -Wy -Zy -l 100%FREE -n root #{@vg}")
          end

          exec("vgchange --available y")
        end

        # Follow https://wiki.archlinux.org/index.php/Partitioning
        # Partition_efi
        # /boot/efi - EFI system partition - 260MB
        # /         - Root

        # Partition_bios
        # None      - Bios Boot Partition - 1MiB
        # /boot     - Boot - 8300
        # /         - Root

        def exec(cmd)
          Getch::Command.new(cmd).run!
        end
      end
    end
  end
end
