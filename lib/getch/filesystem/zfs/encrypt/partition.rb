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
              @partition.swap(@dev_swap)
              @partition.root(@dev_root, "BF00") if @root_part != 1
            else
              @partition.gpt(@dev_gpt)
              @partition.boot(@dev_boot)
              @partition.swap(@dev_swap)
              @partition.root(@dev_root, "BF00") if @root_part != 1
            end
          end

          def cache
            if @dev_log
              exec("sgdisk -n2:0:+4G -t2:BF07 #{cache_disk}")
            end
            if @dev_cache
              exec("sgdisk -n3:0:0 -t3:BF08 #{cache_disk}")
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
