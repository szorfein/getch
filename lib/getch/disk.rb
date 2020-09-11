module Getch
  class Disk
    def initialize(disk, fs)
      @hdd = disk
      @fs = fs
    end

    def efi?
      Dir.exist? '/sys/firmware/efi/efivars'
    end

    def cleaning
      puts "Cleaning data on #{@hdd}, this can take several hours? "
    end

    def format
      if efi? then
        puts "Format disk #{@hdd} for an EFI system with #{@fs}"
        format_efi
      else
        puts "format disk #{@hdd} for a Bios system"
        format_bios
      end
    end

    private

    # follow https://wiki.archlinux.org/index.php/Partitioning
    def format_efi
      # /boot/efi - EFI system partition - 260MB
      # swap      - Linux Swap - size of the ram
      # /         - Root
      # /home     - Home
    end

    def format_bios
      # None      - Bios Boot Partition - 1MiB
      # swap      - Linux Swap - size of the ram
      # /         - Root
      # /home     - Home
    end
  end
end
