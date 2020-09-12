module Getch
  class Disk
    def initialize(disk, fs)
      @hdd = disk
      @fs = fs
    end

    def efi?
      Dir.exist? '/sys/firmware/efi/efivars'
    end

    # https://wiki.archlinux.org/index.php/Securely_wipe_disk
    def cleaning
      puts
      print "Cleaning data on #{@hdd}, can be long, avoid this on Flash Memory (SSD,USB,...) ? (n,y) "
      case gets.chomp
      when /^y|^Y/
        system("dd if=/dev/urandom of=/dev/#{@hdd} bs=4M status=progress")
      else
        return
      end
    end

    def partition
      system("sgdisk --zap-all /dev/#{@hdd}")
      if efi? then
        puts "Partition disk #{@hdd} for an EFI system"
        partition_efi
      else
        puts "Partition disk #{@hdd} for a Bios system"
        partition_bios
      end
    end

    def format
      puts "Format #{@hdd} with #{@fs}"
      if efi? then
        system("mkfs.vfat -F32 /dev/#{@hdd}1")
        system("mkswap /dev/#{@hdd}2")
        system("swapon /dev/#{@hdd}2")
        system("mkfs.ext4 /dev/#{@hdd}3")
        system("mkfs.ext4 /dev/#{@hdd}4")
      else
        system("mkswap /dev/#{@hdd}2")
        system("swapon /dev/#{@hdd}2")
        system("mkfs.ext4 /dev/#{@hdd}3")
        system("mkfs.ext4 /dev/#{@hdd}4")
      end
    end

    private

    # follow https://wiki.archlinux.org/index.php/Partitioning
    def partition_efi
      # /boot/efi - EFI system partition - 260MB
      # swap      - Linux Swap - size of the ram
      # /         - Root
      # /home     - Home
      system("sgdisk -n1:1M:+260M -t1:EF00 /dev/#{@hdd}") # boot EFI
      system("sgdisk -n2:0:+2G -t2:8200 /dev/#{@hdd}") # swap
      system("sgdisk -n3:0:+15G -t3:8304 /dev/#{@hdd}") # root
      system("sgdisk -n4:0:0 -t3:8302 /dev/#{@hdd}") # home
    end

    def partition_bios
      # None      - Bios Boot Partition - 1MiB
      # swap      - Linux Swap - size of the ram
      # /         - Root
      # /home     - Home
      system("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{@hdd}") # Bios boot
      system("sgdisk -n2:0:+2G -t2:8200 /dev/#{@hdd}") # swap
      system("sgdisk -n3:0:+15G -t3:8304 /dev/#{@hdd}") # root
      system("sgdisk -n4:0:0 -t3:8302 /dev/#{@hdd}") # home
    end
  end
end
