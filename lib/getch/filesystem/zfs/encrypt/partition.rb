module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Partition < Getch::FileSystem::Zfs::Encrypt::Device
          def initialize
            super
            @state = Getch::States.new()
            @clean = Getch::FileSystem::Clean
            @partition = Getch::FileSystem::Partition.new
            @log = Getch::Log.new()
            run
          end

          def run
            return if STATES[:partition ]
            @clean.old_zpool
            @clean.hdd(@disk)
            @clean.external_disk(@disk, @boot_disk, @cache_disk, @home_disk)

            partition
            cache
            @state.partition
          end

          private

          def partition
            if Helpers::efi?
              @partition.efi(@dev_esp)
              @partition.swap(@dev_swap) if !@cache_disk
              @partition.root(@dev_root, "BF00") if @root_part != 1
            else
              @partition.gpt(@dev_gpt)
              @partition.boot(@dev_boot)
              @partition.swap(@dev_swap) if !@cache_disk
              @partition.root(@dev_root, "BF00") if @root_part != 1
            end
          end

          def cache
            if @cache_disk
              mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'
              exec("sgdisk -n1:0:+#{mem} -t1:8200 /dev/#{@cache_disk}")
              exec("sgdisk -n2:0:+4G -t2:BF07 /dev/#{@cache_disk}")
              exec("sgdisk -n3:0:0 -t3:BF08 /dev/#{@cache_disk}")
            end
          end

          # Partition_efi
          # /efi      - EFI system partition - 260MB
          # /         - Root

          # Partition_bios
          # None      - Bios Boot Partition - 1MiB
          # /boot     - Boot - 8300
          # /         - Root

          def exec(cmd)
            Helpers::sys(cmd)
          end
        end
      end
    end
  end
end
