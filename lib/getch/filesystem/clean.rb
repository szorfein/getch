module Getch
  module FileSystem
    module Clean
      def self.clean_hdd(disk)
        return unless disk
        raise ArgumentError, "Disk #{disk} is no found." if ! File.exist? "/dev/#{disk}"

        puts
        print "Cleaning data on #{disk}, can be long, avoid this on Flash Memory (SSD,USB,...) ? [y,N] "
        case gets.chomp
        when /^y|^Y/
          bloc=`blockdev --getbsz /dev/#{disk}`.chomp
          Helpers.sys("dd if=/dev/urandom of=/dev/#{disk} bs=#{bloc} status=progress")
        else
          return
        end
      end

      def self.clean_struct(disk)
        return unless disk
        raise ArgumentError, "Disk #{disk} is no found." unless File.exist? "/dev/#{disk}"

        Helpers.sys("sgdisk -Z /dev/#{disk}")
        Helpers.sys("wipefs -a /dev/#{disk}")
      end

      def self.hdd(*disks)
        disks.each { |d|
          clean_struct(d)
          clean_hdd(d)
        }
      end
      # See https://wiki.archlinux.org/index.php/Solid_state_drive/Memory_cell_clearing
      # for SSD
      def self.sdd
      end

      def self.external_disk(root_disk, *disks)
        disks.each do |d|
          unless d && d != '' && d != nil && d == root_disk
            hdd(d)
          end
        end
      end

      def self.old_vg(disk, vg)
        oldvg = `vgdisplay | grep #{vg}`.chomp
        Helpers.sys("vgremove -f #{vg}") if oldvg != ''
        Helpers.sys("pvremove -f #{disk}") if oldvg != '' and File.exist? disk
      end

      def self.old_zpool
        oldzpool = `zpool status | grep pool:`.gsub(/pool: /, '').delete(' ').split("\n")
        if oldzpool[0] != '' and $?.success?
          oldzpool.each { |p| Helpers.sys("zpool destroy #{p}") if p }
        end
      end
    end
  end
end
