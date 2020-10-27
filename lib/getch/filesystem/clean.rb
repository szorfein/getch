module Getch
  module FileSystem
    module Clean
      def self.hdd(disk)
        puts
        print "Cleaning data on #{disk}, can be long, avoid this on Flash Memory (SSD,USB,...) ? [y,N] "
        case gets.chomp
        when /^y|^Y/
          bloc=`blockdev --getbsz /dev/#{disk}`.chomp
          Helpers::sys("dd if=/dev/urandom of=/dev/#{disk} bs=#{bloc} status=progress")
        else
          return
        end
      end
      # See https://wiki.archlinux.org/index.php/Solid_state_drive/Memory_cell_clearing
      # for SSD
      def self.sdd(disk)
      end

      def self.struct(disk)
        Herpers::sys("sgdisk -Z /dev/#{disk}")
        Helpers::sys("wipefs -a /dev/#{disk}")
      end

      def self.old_vg(disk, vg)
        oldvg = `vgdisplay | grep #{vg}`.chomp
        Helpers::sys("vgremove -f #{vg}") if oldvg != ''
        Helpers::sys("pvremove -f #{disk}") if oldvg != '' and File.exist? disk
      end

      def self.olg_zpool
        oldzpool = `zpool status | grep pool:`.gsub(/pool: /, '').delete(' ').split("\n")
        if oldzpool[0] != "" and $?.success?
          oldzpool.each { |p| Helpers::sys("zpool destroy #{p}") if p }
        end
      end
    end
  end
end
