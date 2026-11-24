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
      run_step(:partition) { @fs::Partition.new }
    end

    def format
      run_step(:format) { @fs::Format.new }
    end

    def mount
      run_step(:mount) { @fs::Mount.new }
    end

    def tarball
      run_step(:tarball) { @os::Tarball.new.x }
    end

    # pre_config
    # Pre configuration before updates and install packages
    # Can contain config for a repository, CPU compilation flags, etc...
    def pre_config
      run_step(:pre_config) { @os::PreConfig.new }
    end

    # update
    # Synchronise and Update the new system
    def update
      run_step(:update) do
        Helpers.mount_all
        @os::Update.new
      end
    end

    def post_config
      run_step(:post_config) { @os::PostConfig.new }
    end

    # Luks_keys
    # Install external keys to avoid enter password multiple times
    def luks_keys
      return unless OPTIONS[:encrypt] && OPTIONS[:fs] != 'zfs'

      run_step(:luks_keys) { CryptSetup.new(DEVS, OPTIONS).keys }
    end

    # terraform
    # Install all the required packages
    # Also add services
    def terraform
      run_step(:terraform) do
        @os::Terraform.new
        @fs::Deps.new
      end
    end

    def services
      run_step(:services) { @os::Services.new }
    end

    # bootloader
    # Install and configure Grub2 or Systemd-boot with Dracut
    # Adding keys for Luks
    def bootloader
      run_step(:bootloader) do
        bootloader = @os::Bootloader.new
        bootloader.dependencies
        @fs::Config.new
        bootloader.install
      end
    end

    # finalize
    # Password for root, etc
    def finalize
      run_step(:finalize) do
        @os::Finalize.new
        puts
        puts '[*!*] Installation finished [*!*]'
        puts
        @fs.end
      end
    end

    private

    def run_step(step)
      return if STATES[step]

      yield
      @state.public_send(step)
    end
  end
end
