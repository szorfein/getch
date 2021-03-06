require_relative '../../../helpers'

module Getch
  module FileSystem
    module Lvm
      module Encrypt
        class Partition < Device
          include Helpers::Cryptsetup

          def initialize
            super
            @state = Getch::States.new()
            @clean = Getch::FileSystem::Clean
            @partition = Getch::FileSystem::Partition.new
            @log = Log.new
            run_partition
          end

          def run_partition
            return if STATES[:partition ]
            @clean.old_vg(@dev_root, @vg)
            @clean.hdd(@disk)
            @clean.external_disk(@disk, @boot_disk, @cache_disk, @home_disk)

            partition
            encrypting
            lvm
            @state.partition
          end

          private

          def partition
            if Helpers::efi?
              @partition.efi(@dev_esp)
              @partition.root(@dev_root, "8e00")
            else
              @partition.gpt(@dev_gpt)
              @partition.boot(@dev_boot)
              @partition.root(@dev_root, "8e00")
            end
          end

          def encrypting
            @log.info("Cryptsetup")
            encrypt(@dev_root)
            open_crypt(@dev_root, "cryptroot")
          end

          def lvm
            mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'
            exec("pvcreate -f #{@luks_root}")
            exec("vgcreate -f #{@vg} #{@luks_root}")
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
          # /efi      - EFI system partition - 260MB
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
end
