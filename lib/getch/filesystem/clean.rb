module Getch
  module FileSystem
    module Clean
      def self.hdd(disk)
        puts
        print "Cleaning data on #{disk}, can be long, avoid this on Flash Memory (SSD,USB,...) ? [y,N] "
        case gets.chomp
        when /^y|^Y/
          bloc=`blockdev --getbsz /dev/#{disk}`.chomp
          exec("dd if=/dev/urandom of=/dev/#{disk} bs=#{bloc} status=progress")
        else
          return
        end
      end
      # See https://wiki.archlinux.org/index.php/Solid_state_drive/Memory_cell_clearing
      # for SSD
      def self.sdd(disk)
      end
    end
  end
end
