# frozen_string_literal: true

require 'getch/command'

module Lvm2
  class Root
    def initialize(devs, options)
      @cache = options[:cache_disk] ||= nil
      @root = devs[:root] ||= nil
      @home = options[:home_disk] ||= nil
      @vg = options[:vg_name] ||= 'vg1'
    end

    def x
      pv_create
      vg_create
      lv_setup
      enable_lvs
    end

    protected

    def pv_create
      devs = [ "/dev/#{@root}" ]
      @cache && devs << "/dev/#{@cache}"
      @home && devs << "/dev/#{@home}"
      devs.each { |d| d && add_pv(d) }
    end

    def vg_create
      devs = [ "/dev/#{@root}" ]
      @cache && devs << "/dev/#{@cache}"
      @home && devs << "/dev/#{@home}"
      add_vg devs
    end

    def lv_setup
      @cache ? add_swap("/dev/#{@cache}") : add_swap
      add_lv_root
      @home ? add_home("/dev/#{@home}") : add_home
    end

    def enable_lvs
      lvchange_y 'home'
      lvchange_y 'swap'
      lvchange_y 'root'
    end

    private

    def add_pv(dev)
      File.exist? dev || @log.fatal("add_pv - no #{dev} exist.")

      Getch::Command.new('pvcreate', '-f', dev)
    end

    def add_vg(*devs)
      Getch::Command.new('vgcreate', '-f', @vg, devs.join(' '))
    end

    def add_swap(dev = nil)
      mem = Getch::Helpers.get_memory
      lvcreate('-L', mem, '-n', 'swap', @vg, dev)
    end

    # if home is available, we use the whole space.
    def add_lv_root
      @home ?
        @root.match?(/[0-9]/) ? add_root : add_root(nil, "/dev/#{@root}") :
        @root.match?(/[0-9]/) ? add_root('16G') : add_root('16G', "/dev/#{@root}")
    end

    def add_root(size = nil, dev = nil)
      arg_size = size ? "-L #{size}" : '-l 100%FREE'
      lvcreate(arg_size, '-n', 'root', @vg, dev)
    end

    def add_home(dev = nil)
      lvcreate('-l', '100%FREE', '-n', 'home', @vg, dev)
    end

    def lvcreate(*args)
      Getch::Command.new('lvcreate', '-y', '-Wy', '-Zy', args)
    end

    def lvchange_y(name)
      return if File.exist? "/dev/#{@vg}/#{name}"

      Getch::Command.new('lvchange', '-ay', "/dev/#{@vg}/#{name}")
    end
  end
end
