# frozen_string_literal: true

module Getch
  module FileSystem
    module Ext4
      class Partition < Getch::FileSystem::Ext4::Device
        def initialize
          super
          @state = Getch::States.new
          @partition = Getch::FileSystem::Partition.new
          run_partition
        end

        def run_partition
          return if STATES[:partition ]

          if Helpers.efi?
            partition_efi
          else
            partition_bios
          end
          @state.partition
        end

        private

        # Follow https://wiki.archlinux.org/index.php/Partitioning
        def partition_efi
          # /efi   - EFI system partition - 260MB
          # swap   - Linux Swap - size of the ram
          # /      - Root
          # /home  - Home
          @partition.efi(@dev_esp)
          @partition.swap(@dev_swap)
          @partition.root(@dev_root, '8304')
          @partition.home(@dev_home, '8302') if @dev_home
        end

        def partition_bios
          # None      - Bios Boot Partition - 1MiB
          # /         - Root
          # swap      - Linux Swap - size of the ram
          # /home     - Home
          @partition.gpt(@dev_gpt)
          @partition.swap(@dev_swap)
          @partition.root(@dev_root, '8304')
          @partition.home(@dev_home, '8302') if @dev_home
        end
      end
    end
  end
end
