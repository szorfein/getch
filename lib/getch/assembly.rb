# frozen_string_literal: true

require 'clean'
require 'nito'

module Getch
  class Assembly
    include NiTo

    def initialize
      @os = Tree::Os.new.select
      @fs = Tree::FS.new.select
      @state = Getch::States.new
    end

    def clean
      return if STATES[:partition]

      print "\nPartition and format disk #{OPTIONS[:disk]}, this will erase all data, continue? (y,N) "
      case gets.chomp
      when /^y|^Y/
      else
        exit
      end

      Clean.new(OPTIONS).x
    end

    def partition
      return if STATES[:partition]

      @fs::Partition.new
      @state.partition
    end

    def format
      return if STATES[:format]

      @fs::Format.new
      @state.format
    end

    def mount
      return if STATES[:mount]

      @fs::Mount.new
      #Helpers.mount_all
      @state.mount
    end

    def tarball
      return if STATES[:tarball]

      @os::Tarball.new.x
      @state.tarball
    end

    def config
      return if STATES[:config]

      @os::Config.new
      @state.config
    end
  end
end
