# frozen_string_literal: true

require 'getch/command'
require 'getch/helpers'

module Mkfs

  # Format a path using mkfs.ext4.
  # @param [string] path, full path e.g /dev/sda1
  #
  def self.ext4(path)
    bs = Getch::Helpers.get_bs(path)
    if bs == '512'
      Getch::Command.new('mkfs.ext4', '-F', path)
    else
      Getch::Command.new('mkfs.ext4', '-F', '-b', bs, path)
    end
  end

  class Root
    def initialize(devs, options)
      @efi = devs[:efi] ||= nil
      @boot = devs[:boot] ||= nil
      @swap = devs[:swap] ||= nil
      @root = devs[:root] ||= nil
      @home = devs[:home] ||= nil
      @fs = options[:fs]
      x
    end

    protected

    def x
      format_efi
      format_boot
      format_swap
      format_root
      format_home
    end

    def format_efi
      @efi || return

      mkfs_vfat "/dev/#{@efi}"
    end

    def format_boot
      @boot || return

      mkfs "/dev/#{@boot}"
    end

    def format_swap
      @swap || return

      mk_swap "/dev/#{@swap}"
    end

    def format_root
      @root || return

      mkfs "/dev/#{@root}"
    end

    def format_home
      @home || return

      mkfs "/dev/#{@home}"
    end

    private

    def mkfs(path)
      case @fs
      when 'ext4' then Mkfs.ext4 path
      when 'xfs' then mkfs_xfs path
      end
    end

    def mkfs_vfat(path)
      Getch::Command.new('mkfs.fat', '-F32', path)
    end

    def mk_swap(path)
      Getch::Command.new('mkswap', '-f', path)
    end

    def mkfs_xfs(path)
      bs = Getch::Helpers.get_bs(path)
      Getch::Command.new('mkfs.xfs', '-f', '-s', "size=#{bs}", path)
    end
  end

  class Lvm < Root
    def initialize(devs, options)
      @vg = options[:vg_name]
      super
    end

    def format_swap
      mk_swap "/dev/#{@vg}/swap"
    end

    def format_root
      mkfs "/dev/#{@vg}/root"
    end

    def format_home
      mkfs "/dev/#{@vg}/home"
    end
  end

  class Encrypt < Root
    def initialize(devs, options)
      @luks = options[:luks_name]
      super
    end

    # Boot is alrealy formatted
    def format_boot
    end

    # Swap will be encrypted after the reboot
    def format_swap
    end

    def format_root
      File.exist? "/dev/mapper/root-#{@luks}" || abort("No root-#{@luks} found")

      mkfs "/dev/mapper/root-#{@luks}"
    end

    def format_home
      @home || return

      mkfs "/dev/mapper/home-#{@luks}"
    end
  end

  class Hybrid < Lvm

    # Boot is alrealy formatted
    def format_boot
    end
  end
end

require_relative 'mkfs/zfs'
