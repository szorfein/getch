# frozen_string_literal: true

module Dracut
  class Zfs < Root
    def initialize(devs, options)
      super
      @zfs = options[:zfs_name] ||= 'pool'
      @encrypt = options[:encrypt]
      @os = options[:os]
    end

    def others
      file = "#{@mountpoint}/etc/dracut.conf.d/zfs.conf"
      echo file, '"nofsck="yes"'
      echo_a file, 'omit_dracutmodules+=" btrfs "'
    end

    # See https://wiki.gentoo.org/wiki/ZFS#ZFS_root
    # https://github.com/openzfs/zfs/blob/master/contrib/dracut/README.dracut.markdown
    def get_line
      @encrypt ?
        without :
        with_swap
    end

    def without
      "root=zfs:r#{@zfs}/ROOT/#{@os} zfs.force=1 zfs.zfs_arc_max=536870912"
    end

    def with_swap
      swap = Getch::Helpers.uuid @swap
      "resume=UUID=#{swap} root=zfs:r#{@zfs}/ROOT/#{@os} zfs.force=1 zfs.zfs_arc_max=536870912"
    end
  end
end
