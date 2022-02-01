require 'nito'

class Fstab
  include NiTo

  def initialize(devs, options)
    @esp = devs[:esp] ||= nil
    @boot = devs[:boot] ||= nil
    @swap = devs[:swap] ||= nil
    @root = devs[:root] ||= nil
    @home = devs[:home] ||= nil
    @mountpoint = options[:mountpoint] ||= '/mnt/getch'
  end

  private

  def gen_uuid
  end
end
