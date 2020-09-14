require 'yaml'

module Getch
  class States
    def initialize
      @file = File.join('/tmp/install_gentoo.yaml')
      load_state
    end

    def partition
      STATES[:partition] = true
      save
    end

    def format
      STATES[:format] = true
      save
    end

    def mount
      STATES[:mount] = true
      save
    end

    def stage3
      STATES[:gentoo_base] = true
      save
    end

    def config
      STATES[:gentoo_config] = true
      save
    end

    def update
      STATES[:gentoo_update] = true
      save
    end

    def kernel
      STATES[:gentoo_kernel] = true
      save
    end

    private

    def save
      File.open(@file, 'w') { |f| YAML::dump(STATES, f) }
    end

    def load_state()
      if File.exist? @file
        state_file = YAML.load_file(@file)
        STATES.merge!(state_file)
      else
        save
        STDERR.puts "Initialize states"
      end
    end
  end
end
