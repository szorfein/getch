module Getch
  module FileSystem
    module Ext4
      class Partition < Getch::FileSystem::Ext4::Device
        def initialize
          super
          @state = Getch::States.new()
          @clean = Getch::FileSystem::Clean
          @partition = Getch::FileSystem::Partition.new
          run_partition
        end

        def run_partition
          return if STATES[:partition ]
          @clean.struct(@disk)
          @clean.hdd(@disk)
          if Helpers::efi?
            partition_efi
          else
            partition_bios
          end
          @state.partition
        end

        private

        # Follow https://wiki.archlinux.org/index.php/Partitioning
        def partition_efi
          # /boot/efi - EFI system partition - 260MB
          # swap      - Linux Swap - size of the ram
          # /         - Root
          # /home     - Home
          @partition.efi(@disk)
          @partition.swap(@disk)
          @partition.root(3, "8304", @disk)
          @partition.home(4, "8302", @disk) if @dev_home
        end

        def partition_bios
          # None      - Bios Boot Partition - 1MiB
          # /         - Root
          # swap      - Linux Swap - size of the ram
          # /home     - Home
          @partition.gpt(@disk)
          @partition.swap(@disk)
          @partition.root(3, "8304", @disk)
          @partition.home(4, "8302", @disk) if @dev_home
        end
      end
    end
  end
end
