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

      @fs::Mount.new.run
      @state.mount
    end

    def tarball
      return if STATES[:tarball]

      @os::Tarball.new.x
      @state.tarball
    end

    # pre_config
    # Pre configuration before updates and install packages
    # Can contain config for a repository, CPU compilation flags, etc...
    def pre_config
      return if STATES[:pre_config]

      @os::PreConfig.new
      @state.pre_config
    end

    # update
    # Synchronise and Update the new system
    def update
      return if STATES[:update]

      Helpers.mount_all
      @os::Update.new
      @state.update
    end

    def post_config
      #return if STATES[:post_config]

      @os::PostConfig.new
      #@state.post_config
    end
  end
end
