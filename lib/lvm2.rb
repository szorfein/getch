# frozen_string_literal: true

require 'getch/command'

module Lvm2
  # Configure system with lvm
  class Root
    def initialize(devs, options)
      @cache = options[:cache_disk] ||= nil
      @root = devs[:root] ||= nil
      @home = options[:home_disk] ||= nil
      @vg = options[:vg_name] ||= 'vg0'
    end

    def x
      load_datas
      pv_create
      vg_create
      lv_setup
      enable_lvs
    end

    protected

    def load_datas
      @path_root = "/dev/#{@root}"
      @path_cache = "/dev/#{@cache}"
      @path_home = "/dev/#{@home}"
    end

    def pv_create
      devs = [@path_root]
      @cache && devs << @path_cache
      @home && devs << @path_home
      devs.each { |d| d && add_pv(d) }
    end

    def vg_create
      devs = [@path_root]
      @cache && devs << @path_cache
      @home && devs << @path_home
      add_vg devs
    end

    def lv_setup
      @cache ? add_swap(@path_cache) : add_swap
      add_lv_root
      @home ? add_home(@path_home) : add_home
    end

    def enable_lvs
      lvchange_y 'home'
      lvchange_y 'swap'
      lvchange_y 'root'
    end

    private

    def add_pv(dev)
      File.exist?(dev) || @log.fatal("add_pv - no #{dev} exist.")

      Getch::Command.new('pvcreate', '-f', dev)
    end

    def add_vg(*devs)
      Getch::Command.new('vgcreate', '-f', @vg, devs.join(' '))
    end

    def add_swap(dev = nil)
      mem = "#{Getch::OPTIONS[:swap_size]}M"
      lvcreate('-L', mem, '-n', 'swap', @vg, dev)
    end

    # if home is available, we use the whole space.
    def add_lv_root
      size = "#{OPTIONS[:root_size]}G" # in gigabyte
      if @home
        @root.match?(/[0-9]/) ? add_root : add_root(nil, @path_root)
      else
        @root.match?(/[0-9]/) ? add_root(size) : add_root(size, @path_root)
      end
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

  # Configure hybrid system (encrypt + lvm)
  class Hybrid < Root
    def initialize(devs, options)
      super
      @luks = options[:luks_name]
    end

    def load_datas
      @path_root = "/dev/mapper/root-#{@luks}"
      @path_cache = "/dev/mapper/cache-#{@luks}"
      @path_home = "/dev/mapper/home-#{@luks}"
    end
  end
end
