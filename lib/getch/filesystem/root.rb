module Getch
  module FileSystem
    class Root
      def initialize(disk)
        @disk = disk
        @fs = nil
        @state = Getch::States.new()
      end

      # https://wiki.archlinux.org/index.php/Securely_wipe_disk
      def cleaning
        return if STATES[:partition ]
        puts
        print "Cleaning data on #{@disk}, can be long, avoid this on Flash Memory (SSD,USB,...) ? (n,y) "
        case gets.chomp
        when /^y|^Y/
          system("dd if=/dev/urandom of=/dev/#{@disk} bs=4M status=progress")
        else
          return
        end
      end

      def partition
        return if STATES[:partition]
        Helpers::exec_or_die("sgdisk --zap-all /dev/#{@disk}")
        Helpers::exec_or_die("wipefs -a /dev/#{@disk}")
        if Helpers::efi? then
          puts "Partition disk #{@disk} for an EFI system"
          partition_efi
        else
          puts "Partition disk #{@disk} for a Bios system"
          partition_bios
        end
        @state.partition
      end

      def format
        return if STATES[:format]
        puts "Format #{@disk} with #{@fs}"
        if Helpers::efi? then
          format_efi
        else
          format_bios
        end
        @state.format
      end

      private

      def partition_efi
      end

      def partition_bios
      end

      def format_efi
      end

      def format_bios
      end
    end
  end
end
