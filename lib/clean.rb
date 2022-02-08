# frozen_string_literal: true

require 'nito'
require_relative 'getch/command'
require_relative 'getch/log'

class Clean
  include NiTo

  def initialize(args)
    @root = args[:disk] ||= nil
    @boot = args[:boot_disk] ||= nil
    @home = args[:home_disk] ||= nil
    @cache = args[:cache_disk] ||= nil
    @vg = args[:vg_name] ||= nil
    @luks = args[:luks_name] ||= nil
    @log = Getch::Log.new
    @mountpoint = args[:mountpoint] ||= '/mnt/getch'
  end

  def x
    umount_all
    swap_off
    disable_lvs
    cryptsetup_close
    old_lvm
    zap_all @root, @boot, @home, @cache
  end

  protected

  def umount_all
    paths = []
    File.open('/proc/mounts').each do |l|
      tmp = l.split(' ') if l =~ /#{@mountpoint}/
      tmp && paths << tmp[1]
    end
    paths.each { |p| umount_r p }
    umount '/tmp/boot'
  end

  def swap_off
    swapoff @root
    File.exist?("/dev/#{@vg}/swap") && swapoff_dm("#{@vg}-swap")
  end

  def disable_lvs
    lvchange_n 'home'
    lvchange_n 'swap'
    lvchange_n 'root'
  end

  def cryptsetup_close
    close "boot-#{@luks}"
    close "root-#{@luks}"
    close "home-#{@luks}"
  end

  def old_lvm
    lvm = `lvs | grep #{@vg}`
    lvm.match?(/#{@vg}/) || return

    vgremove
    pvremove @root, @home, @cache
  end

  def zap_all(*devs)
    devs.each { |d| zap(d) }
  end

  private

  def umount_r(dir)
    dir || return

    cmd 'umount', '-R', dir if mount? dir
  end

  def zap(dev)
    dev || return

    cmd 'sgdisk', '-Z', "/dev/#{dev}"
  end

  def lvchange_n(name)
    return unless File.exist? "/dev/#{@vg}/#{name}"

    cmd 'lvchange', '-an', "/dev/#{@vg}/#{name}"
  end

  def close(name)
    return unless File.exist? "/dev/mapper/#{name}"

    cmd 'cryptsetup', 'close', name
  end

  def vgremove
    cmd 'vgremove', '-y', @vg
  end

  def pvremove(*devs)
    devs.each { |d| pvdel(d) }
  end

  def pvdel(dev)
    dev || return

    disk = dev[/[a-z]*/]
    disk.match?(/[a-z]{3}/) || @log.fatal("pvdel - No disk #{dev} - #{disk}")

    cmd 'pvremove', '-f', "/dev/#{disk}*"
  end

  def cmd(*args)
    Getch::Command.new(args)
  end
end
