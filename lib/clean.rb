# frozen_string_literal: true

require 'nito'
require_relative 'getch/command'

class Clean
  include NiTo

  def initialize(args)
    @root = args[:disk] ||= nil
    @boot = args[:boot_disk] ||= nil
    @home = args[:home_disk] ||= nil
    @cache = args[:cache_disk] ||= nil
    @mountpoint = args[:mountpoint] ||= '/mnt/getch'
  end

  def x
    umount_all
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

  def cmd(*args)
    Getch::Command.new(args)
  end
end
