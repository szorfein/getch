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
      system("sgdisk --zap-all /dev/#{@hdd}")
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
      system("sgdisk -n1:1M:+260M -t1:EF00 /dev/#{@hdd}") # boot EFI
      system("sgdisk -n2:0:+2G -t2:8200 /dev/#{@hdd}") # swap
      system("sgdisk -n3:0:+50G -t3:8304 /dev/#{@hdd}") # root
      system("sgdisk -n4:0:0 -t3:8302 /dev/#{@hdd}") # home
    end

    def format_bios
      # None      - Bios Boot Partition - 1MiB
      # swap      - Linux Swap - size of the ram
      # /         - Root
      # /home     - Home
      system("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{@hdd}") # Bios boot
      system("sgdisk -n2:0:+2G -t2:8200 /dev/#{@hdd}") # swap
      system("sgdisk -n3:0:+50G -t3:8304 /dev/#{@hdd}") # root
      system("sgdisk -n4:0:0 -t3:8302 /dev/#{@hdd}") # home
    end
  end
end
