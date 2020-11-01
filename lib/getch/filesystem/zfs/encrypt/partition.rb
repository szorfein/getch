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
            @clean.struct(@disk, @cache_disk, @home_disk)
            @clean.hdd(@disk, @cache_disk, @home_disk)
            partition
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
