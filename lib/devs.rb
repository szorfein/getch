# frozen_string_literal: true

require 'getch/device'

module Devs
  class Settings
    def initialize(args, options)
      @args = args
      @start = args[:start] ||= nil
      @boot = args[:boot] ||= nil
      @swap = args[:swap] ||= nil
      @root = args[:root] ||= nil
      @options = options
      @encrypt = options[:encrypt] ||= false
      @lvm = options[:lvm] ||= false
      @whole = nil
      @fs = options[:fs]
      @tree = TREE[@fs.to_sym]
      x
    end

    def x
      add_boot
      add_swap
      add_root
      add_home
    end

    protected

    def add_boot
      @options[:boot_disk] || return

      @fs == 'zfs' ?
        @tree.new(@options[:boot_disk], start: @start, boot: @boot, systemd_boot: systemd_boot?) :
        @tree.new(@options[:boot_disk], start: @start, boot: @boot)

      @args.delete :start
      @args.delete :boot if @boot
    end

    def add_swap
      @options[:cache_disk] || return

      @fs == 'zfs' ?
        @tree.new(@options[:cache_disk], swap: @swap, zfs_cache: true) :
        @tree.new(@options[:cache_disk], swap: @swap)
      @args.delete :swap if @swap
    end

    def add_root
      if @encrypt or @lvm or @fs == 'zfs' then @whole = true end
      @args[:whole] = @whole

      if systemd_boot? and @fs == 'zfs' then @args.delete :boot end
      @tree.new(@options[:disk], @args)
    end

    def add_home
      @options[:home_disk] || return

      if @encrypt or @lvm or @fs == 'zfs' then @whole = true end
      @tree.new(@options[:home_disk], home: true, whole: @whole)
    end

    private

    def efi?
      Dir.exist? '/sys/firmware/efi/efivars'
    end

    def systemd_boot?
      @options[:os] == 'gentoo' and not @options[:musl] and efi?
    end
  end

  class Matrice
    def initialize(disk, args)
      @disk = disk
      @start = args[:start] ||= nil
      @boot = args[:boot] ||= nil
      @swap = args[:swap] ||= nil
      @root = args[:root] ||= nil
      @home = args[:home] ||= nil
      @whole = args[:whole] ||= false
      @device = Getch::Device.new
      @@part = 1
      x
    end

    def x
      start
      boot
      swap
      root
      home
    end

    protected

    def start
      @start || return

      efi? ? add_efi : add_gpt
    end

    def add_efi
      @device.efi "#{@disk}#{@@part}"
      @@part += 1
    end

    def add_gpt
      @device.gpt "#{@disk}#{@@part}"
      @@part += 1
    end

    def boot
      @boot || return

      @device.boot "#{@disk}#{@@part}"
      @@part += 1
    end

    def swap
      @swap || return

      @device.swap "#{@disk}#{@@part}"
      @@part += 1
    end

    def root
      @root || return

      if @whole && @@part == 1
        @device.root @disk
      else
        @device.root "#{@disk}#{@@part}"
        @@part += 1
      end
    end

    def home
      @home || return

      if @whole && @@part == 1
        @device.home @disk
      else
        @device.home "#{@disk}#{@@part}"
        @@part += 1
      end
    end

    private

    def efi?
      Dir.exist? '/sys/firmware/efi/efivars'
    end
  end

  class MatExt4 < Matrice
  end

  class MatZfs < Matrice
    def initialize(disk, args)
      @zfs_cache = args[:zfs_cache] ||= nil
      @systemd_boot = args[:systemd_boot] ||= false
      super
    end

    def boot
      @boot || return

      @systemd_boot && return

      @device.boot "#{@disk}#{@@part}"
      @@part += 1
    end

    def swap
      @swap || return

      if @zfs_cache
        @device.swap "#{@disk}#{@@part}"
        @@part += 1
        @device.zlog "#{@disk}#{@@part}"
        @@part += 1
        @device.zcache "#{@disk}#{@@part}"
      else
        @device.swap "#{@disk}#{@@part}"
        @@part += 1
      end
    end
  end

  TREE = {
    ext4: MatExt4,
    zfs: MatZfs,
  }
end
