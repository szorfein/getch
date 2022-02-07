require 'getch/log'

module Mkfs
  class Zfs < Root
    def initialize(devs, options)
      @mountpoint = options[:mountpoint]
      @zfs = options[:zfs_name] ||= 'pool'
      @os = options[:os]
      @encrypt = options[:encrypt]
      @zlog = devs[:zlog] ||= nil
      @zcache = devs[:zcache] ||= nil
      @rpool = "r#{@zfs}"
      @bpool = "b#{@zfs}"
      @hpool = "h#{@zfs}"
      @log = Getch::Log.new
      super
    end

    # reorder process, root should be formatted first
    def x
      format_efi
      format_root
      format_boot
      format_swap
      format_home
      add_dataset
    end

    def format_boot
      @boot || return

      id = Getch::Helpers.get_id(@boot)
      ashift = get_ashift @boot
      args = "-f -o ashift=#{ashift} -o autotrim=on"
      args << ' -o compatibility=grub2'
      args << ' -O acltype=posixacl -O canmount=off -O compression=lz4'
      args << ' -O devices=off -O normalization=formD -O atime=off -O xattr=sa'
      args << ' -O mountpoint=/boot'
      args << " -R #{@mountpoint} #{@bpool} #{id}"
      sh 'zpool', 'create', args
    end

    def format_swap
      mk_swap "/dev/#{@swap}"
      add_zlog
      add_zcache
    end

    def add_zlog
      @zlog || return

      id = Getch::Helpers.get_id(@zlog)
      sh 'zpool', 'add', @rpool, 'log', id
    end

    def add_zcache
      @zcache || return

      id = Getch::Helpers.get_id(@zcache)
      sh 'zpool', 'add', @rpool, 'cache', id
    end

    def format_root
      id = Getch::Helpers.get_id(@root)
      ashift = get_ashift @root
      args = "-f -o ashift=#{ashift} -o autotrim=on"
      @encrypt && args << ' -O encryption=aes-256-gcm'
      @encrypt && args << ' -O keylocation=prompt -O keyformat=passphrase'
      args << ' -O acltype=posixacl -O canmount=off -O compression=lz4'
      args << ' -O xattr=sa -O mountpoint=/'
      args << " -R #{@mountpoint} #{@rpool} #{id}"
      sh 'zpool', 'create', args
    end

    def format_home
      @home || return

      id = Getch::Helpers.get_id(@home)
      ashift = get_ashift @home
      args = "-f -o ashift=#{ashift} -o autotrim=on"
      @encrypt && args << ' -O encryption=aes-256-gcm'
      @encrypt && args << ' -O keylocation=prompt -O keyformat=passphrase'
      args << ' -O acltype=posixacl -O canmount=off -O compression=lz4'
      args << ' -O xattr=sa -O mountpoint=/home'
      args << " -R #{@mountpoint} #{@hpool} #{id}"
      sh 'zpool', 'create', args
    end

    def add_dataset
      zfs_create "-o canmount=off -o mountpoint=none #{@rpool}/ROOT"
      zfs_create "-o canmount=noauto -o mountpoint=/ #{@rpool}/ROOT/#{@os}"

      zfs_create "-o canmount=off #{@rpool}/ROOT/#{@os}/usr"
      zfs_create "#{@rpool}/ROOT/#{@os}/usr/src"

      zfs_create "-o canmount=off #{@rpool}/ROOT/#{@os}/var"
      zfs_create "#{@rpool}/ROOT/#{@os}/var/log"
      zfs_create "#{@rpool}/ROOT/#{@os}/var/db"
      zfs_create "#{@rpool}/ROOT/#{@os}/var/tmp"
      zfs_create "#{@rpool}/ROOT/#{@os}/var/lib/docker"

      boot_dataset
      user_dataset
    end

    def boot_dataset
      @boot || return

      zfs_create "-o canmount=off -o mountpoint=none #{@bpool}/BOOT"
      zfs_create "-o canmount=noauto -o mountpoint=/boot #{@bpool}/BOOT/#{@os}"
    end

    def user_dataset
      if @home
        zfs_create "-o canmount=off -o mountpoint=/ #{@hpool}/USERDATA"
        zfs_create "-o canmount=on -o mountpoint=/root #{@hpool}/USERDATA/root"
        zfs_create "-o canmount=on -o mountpoint=/home/#{@user} #{@hpool}/USERDATA/home"
      else
        zfs_create "-o canmount=off -o mountpoint=/ #{@rpool}/USERDATA"
        zfs_create "-o canmount=on -o mountpoint=/root #{@rpool}/USERDATA/root"
        zfs_create "-o canmount=on -o mountpoint=/home/#{@user} #{@rpool}/USERDATA/home"
      end
    end

    private

    def get_ashift(dev)
      bs = Getch::Helpers.get_bs("/dev/#{dev}")
      case bs
      when /8096/ then 13
      when /4096/ then 12
      else 9
      end
    end

    def zfs_create(*args)
      Getch::Command.new('zfs', 'create', args)
    end

    def sh(*args)
      @encrypt ?
        cmd_crypt(args) :
        Getch::Command.new(args)
    end

    def cmd_crypt(*args)
      system args.join(' ')
      return if $?.exitstatus == 0

      @log.dbg $?
      @log.fatal 'die'
    end
  end
end
