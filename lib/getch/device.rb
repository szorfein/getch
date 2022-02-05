# frozen_string_literal: true

require 'yaml'

module Getch
  class Device
    def initialize
      @file = File.join('/tmp/getch_devs.yaml')
      load_devs
    end

    def gpt(dev)
      DEVS[:gpt] = dev
      save
    end

    def efi(dev)
      DEVS[:efi] = dev
      save
    end

    def boot(dev)
      DEVS[:boot] = dev
      save
    end

    def swap(dev)
      DEVS[:swap] = dev
      save
    end

    def root(dev)
      DEVS[:root] = dev
      save
    end

    def home(dev)
      DEVS[:home] = dev
      save
    end

    def zlog(dev)
      DEVS[:zlog] = dev
      save
    end

    def zcache(dev)
      DEVS[:zcache] = dev
      save
    end

    private

    def load_devs
      if File.exist? @file
        DEVS.merge! YAML.load_file @file
      else
        save
        warn "Init devs at #{@file}"
      end
    end

    def save
      File.open(@file, 'w') { |f| YAML.dump(DEVS, f) }
    end
  end
end
