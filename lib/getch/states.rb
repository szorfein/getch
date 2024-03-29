# frozen_string_literal: true

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

    def tarball
      STATES[:tarball] = true
      save
    end

    def pre_config
      STATES[:pre_config] = true
      save
    end

    def update
      STATES[:update] = true
      save
    end

    def post_config
      STATES[:post_config] = true
      save
    end

    def terraform
      STATES[:terraform] = true
      save
    end

    def services
      STATES[:services] = true
      save
    end

    def luks_keys
      STATES[:luks_keys] = true
      save
    end

    def bootloader
      STATES[:bootloader] = true
      save
    end

    def finalize
      STATES[:finalize] = true
      save
    end

    private

    def save
      File.open(@file, 'w') { |f| YAML.dump(STATES, f) }
    end

    def load_state
      if File.exist? @file
        state_file = YAML.load_file(@file)
        STATES.merge!(state_file)
      else
        save
        warn 'Initialize states'
      end
    end
  end
end
