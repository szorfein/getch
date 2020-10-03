module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Partition < Getch::FileSystem::Ext4::Encrypt::Device
          def initialize
            super
            @state = Getch::States.new()
            @log = Log.new
            run_partition
          end

          def run_partition
            return if STATES[:partition ]
            clear_struct
            cleaning
            if Helpers::efi?
              partition_efi
              encrypt_efi
            else
              partition_bios
              encrypt_bios
            end
            @state.partition
          end

          private

          def clear_struct
            exec("sgdisk -Z /dev/#{@disk}")
            exec("wipefs -a /dev/#{@disk}")
          end

          def cleaning
            puts
            print "Cleaning data on #{@disk}, can be long, avoid this on Flash Memory (SSD,USB,...) ? (n,y) "
            case gets.chomp
            when /^y|^Y/
              bloc=`blockdev --getbsz /dev/#{@disk}`.chomp
              exec("dd if=/dev/urandom of=/dev/#{@disk} bs=#{bloc} status=progress")
            else
              return
            end
          end

          # Follow https://wiki.archlinux.org/index.php/Partitioning
          def partition_efi
            # /boot/efi - EFI system partition - 260MB
            # /         - Root
            # swap      - Linux Swap - size of the ram
            # /home     - Home
            mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'

            exec("sgdisk -n1:1M:+260M -t1:EF00 /dev/#{@disk}")
            exec("sgdisk -n2:0:+15G -t2:8309 /dev/#{@disk}")
            exec("sgdisk -n3:0:+#{mem} -t3:8200 /dev/#{@disk}")
            exec("sgdisk -n4:0:0 -t4:8309 /dev/#{@disk}") if @dev_home
          end

          def encrypt_efi
            @log.info("Format root")
            Helpers::sys("cryptsetup luksFormat #{@dev_root}")
            @log.debug("Opening root")
            Helpers::sys("cryptsetup open --type luks #{@dev_root} cryptroot")
            encrypt_home
          end

          def encrypt_bios
            @log.info("Format root for bios")
            Helpers::sys("cryptsetup luksFormat --type luks1 #{@dev_root}")
            @log.debug("Opening root")
            Helpers::sys("cryptsetup open --type luks1 #{@dev_root} cryptroot")
            encrypt_home
          end

          def encrypt_home
            if @dev_home then
              create_secret_keys
              @log.info("Format home with #{@key_path}")
              Helpers::sys("cryptsetup luksFormat #{@dev_home} #{@key_path}")
              @log.debug("Open home with key #{@key_path}")
              exec("cryptsetup open --type luks -d #{@key_path} #{@dev_home} crypthome")
            end
          end

          def create_secret_keys
            return if ! @dev_home
            @log.info("Creating secret keys")
            keys_dir = "/root/secretkeys"
            key_name = "crypto_keyfile.bin"
            @key_path = "#{keys_dir}/#{key_name}"
            FileUtils.mkdir keys_dir, mode: 0700 if ! Dir.exist?(keys_dir)
            Getch::Command.new("dd bs=512 count=4 if=/dev/urandom of=#{@key_path}").run!
          end

          def partition_bios
            # None      - Bios Boot Partition - 1MiB
            # /         - Root
            # swap      - Linux Swap - size of the ram
            # /home     - Home
            mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'

            exec("sgdisk -n1:1MiB:+1MiB -t1:EF02 /dev/#{@disk}")
            exec("sgdisk -n2:0:+15G -t2:8309 /dev/#{@disk}")
            exec("sgdisk -n3:0:+#{mem} -t3:8200 /dev/#{@disk}")
            exec("sgdisk -n4:0:0 -t4:8309 /dev/#{@disk}") if @dev_home
          end

          def exec(cmd)
            Getch::Command.new(cmd).run!
          end
        end
      end
    end
  end
end
