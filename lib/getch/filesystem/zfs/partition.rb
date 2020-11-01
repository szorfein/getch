module Getch
  module FileSystem
    module Zfs
      class Partition < Getch::FileSystem::Zfs::Device
        def initialize
          super
          @clean = Getch::FileSystem::Clean
          @partition = Getch::FileSystem::Partition.new
          @state = Getch::States.new()
          @log = Getch::Log.new()
          run_partition
        end

        def run_partition
          return if STATES[:partition ]
          @clean.old_zpool
          @clean.struct(@disk, @cache_disk, @home_disk)
          @clean.hdd(@disk, @cache_disk, @home_disk)
          partition
          @state.partition
        end

        private

        def partition
          if @efi
            @partition.efi(@dev_esp)
            @partition.swap(@dev_swap)
            @partition.root(@dev_root, "BF00") if @root_part != 1
          else
            @partition.gpt(@dev_gpt)
            # Boot pool for GRUB2
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
          Getch::Command.new(cmd).run!
        end
      end
    end
  end
end
