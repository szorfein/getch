# frozen_string_literal: true

require 'clean'
require 'nito'
require 'cryptsetup'

module Getch
  # define steps/order for getch
  class Assembly
    include NiTo

    def initialize
      @os = Tree::Os.new.select
      @fs = Tree::FS.new.select
      @state = Getch::States.new
      Getch::Device.new
      init_devs
    end

    def init_devs
      DEVS[:root] && return

      @fs::Device.new
      DEVS[:root] || Log.new.fatal('No root, device prob !')
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
      return if STATES[:post_config]

      @os::PostConfig.new
      @state.post_config
    end

    # Luks_keys
    # Install external keys to avoid enter password multiple times
    def luks_keys
      return unless OPTIONS[:encrypt] && OPTIONS[:fs] != 'zfs'

      return if STATES[:luks_keys]

      CryptSetup.new(DEVS, OPTIONS).keys
      @state.luks_keys
    end

    # terraform
    # Install all the required packages
    # Also add services
    def terraform
      return if STATES[:terraform]

      # @fs::PreDeps.new
      @os::Terraform.new
      @fs::Deps.new
      @state.terraform
    end

    def services
      return if STATES[:services]

      @os::Services.new
      @state.services
    end

    # bootloader
    # Install and configure Grub2 or Systemd-boot with Dracut
    # Adding keys for Luks
    def bootloader
      return if STATES[:bootloader]

      bootloader = @os::Bootloader.new
      bootloader.dependencies
      @fs::Config.new
      bootloader.install
      @state.bootloader
    end

    # finalize
    # Password for root, etc
    def finalize
      return if STATES[:finalize]

      @os::Finalize.new
      puts
      puts '[*!*] Installation finished [*!*]'
      puts
      @fs.end
      @state.finalize
    end
  end
end
