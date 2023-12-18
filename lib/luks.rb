# frozen_string_literal: true

require 'nito'
require 'getch/log'
require 'getch/command'
require 'English'

module Luks
  # define luks name, path, etc...
  class Main
    include Luks
    include NiTo

    Permission = Class.new(StandardError)

    def initialize(disk, options)
      @disk = disk
      @format = options[:fs]
      @mountpoint = options[:mountpoint]
      @luks_type = nil
      @key_dir = nil
      @key_name = nil
      @mount = nil
      @bootloader = false
      @log = Getch::Log.new
      @bs = sector_size
    end

    def encrypt
      args = @luks_type == 'luks2' ? "#{@command_args} --sector-size #{@bs}" : @command_args
      @log.info "Encrypting #{@luks_name} > #{@disk}...\n"
      cmd_crypt 'cryptsetup', 'luksFormat', args, "/dev/#{@disk}"
    end

    def encrypt_with_key
      make_key
      args = if @luks_type == 'luks2'
               "#{@command_args} -q --sector-size #{@bs} -d #{@full_key_path}"
             else
               "#{@command_args} -q -d #{@full_key_path}"
             end
      @log.info "Encrypting #{@luks_name} with #{@full_key_path}...\n"
      cmd_crypt 'cryptsetup', 'luksFormat', args, "/dev/#{@disk}"
    end

    def open
      return if File.exist? "/dev/mapper/#{@luks_name}"

      @log.info "Opening #{@luks_name} > #{@disk}...\n"
      cmd_crypt 'cryptsetup', 'open', @command_args, "/dev/#{@disk}", @luks_name

      raise "No dev /dev/mapper/#{@luks_name}, open it first..." unless File.exist? "/dev/mapper/#{@luks_name}"
    end

    def open_with_key(file = nil)
      return if File.exist? "/dev/mapper/#{@luks_name}"

      @full_key_path = "#{@mountpoint}#{@key_path}"
      key = file ? file : @full_key_path
      @log.info "Opening #{@luks_name} disk #{@disk} with #{key}...\n"
      cmd_crypt 'cryptsetup', 'open', @command_args, '-d', key, "/dev/#{@disk}", @luks_name
    end

    def format
      case @format
      when 'ext4'
        format_ext4
      when 'xfs'
        format_xfs
      when 'fat'
        format_fat
      else
        @log.fatal "#{@format} not yet supported."
      end
    end

    def external_key
      make_key
      @log.info "Adding key for #{@luks_name}...\n"
      cmd_crypt 'cryptsetup', 'luksAddKey', "/dev/#{@disk}", @full_key_path
    end

    def write_config
      config
      perm
    end

    def mount
      mountpoint = @luks_name =~ /^root/ ? @mountpoint : "#{@mountpoint}#{@mount}"
      NiTo.mount "/dev/mapper/#{@luks_name}", mountpoint
    end

    def close
      return unless File.exist? "/dev/mapper/#{@luks_name}"

      @log.info "Closing #{@luks_name}...\n"
      cmd_crypt 'cryptsetup', 'close', @luks_name
    end

    def gen_datas; end

    protected

    def make_key
      @key_path = "#{@key_dir}/#{@key_name}"
      @full_key_path = "#{@mountpoint}#{@key_path}"
      @log.info "Generating key...\n"
      mkdir "#{@mountpoint}#{@key_dir}"
      sh 'dd', 'bs=512', 'count=8', 'iflag=fullblock', 'if=/dev/urandom', "of=#{@full_key_path}"
    end

    # https://wiki.archlinux.org/title/Advanced_Format#File_systems
    def format_ext4
      @log.info "Formating disk with #{@format}...\n"
      Mkfs.ext4 "/dev/mapper/#{@luks_name}"
    end

    # https://wiki.archlinux.org/title/Advanced_Format#File_systems
    def format_xfs
      @log.info "Formating disk with #{@format}...\n"
      sh 'mkfs.xfs', '-f', '-s', "size=#{@bs}", "/dev/mapper/#{@luks_name}"
    end

    def config
      @key_path = "#{@key_dir}/#{@key_name}"
      uuid = Getch::Helpers.uuid @disk
      @log.info "Writing configs for #{@luks_name}...\n"

      @log.info " * Writing #{@mountpoint}/etc/crypttab..."
      line = "#{@luks_name} UUID=#{uuid} #{@key_path} luks"
      echo_a "#{@mountpoint}/etc/crypttab", line
      @log.result_ok

      config_openrc
      config_grub
    end

    # https://wiki.gentoo.org/wiki/Dm-crypt#Configuring_dm-crypt
    def config_openrc
      Getch::Helpers.openrc? || return

      conf = "#{@mountpoint}/etc/conf.d/dmcrypt"
      uuid = Getch::Helpers.uuid @disk
      echo_a conf, "target=#{@luks_name}"
      echo_a conf, "source=UUID=\"#{uuid}\""
      echo_a conf, "key=#{@key_path}"
    end

    def config_grub
      # return unless Getch::Helpers.grub? && !Getch::Helpers.systemd_minimal?
      return unless @bootloader && Getch::Helpers.grub?

      @log.info ' * Writing to /etc/default/grub...'
      line = 'GRUB_ENABLE_CRYPTODISK=y'
      echo_a "#{@mountpoint}/etc/default/grub", line
      @log.result_ok
    end

    def perm
      @key_path = "#{@key_dir}/#{@key_name}"
      @full_key_path = "#{@mountpoint}#{@key_path}"
      @log.info "Enforcing permission on #{@full_key_path}..."
      File.chmod(0400, "#{@mountpoint}#{@key_dir}")
      File.chmod(0000, @full_key_path)
      File.chown(0, 0, @full_key_path)
      @log.result_ok
    end

    private

    def sector_size
      @disk || @log.fatal("No disk for #{@luks_name}.")

      sh 'blockdev', '--getpbsz', "/dev/#{@disk}"
    end

    def cmd_crypt_raw(*args)
      system args.join(' ')
      return if $CHILD_STATUS.success?

      @log.dbg args.join(' ')
      @log.dbg $CHILD_STATUS.success
      @log.fatal 'die'
    end

    def cmd_crypt(*args)
      cmd_crypt_raw args
    rescue StandardError => e
      @log.fatal e
    end

    def sh(*args)
      Getch::Command.new(args)
    end
  end

  # Boot can decrypt all other partitions.
  class Boot < Main
    def initialize(disk, options)
      super
      @luks_type = 'luks1'
      @key_dir = '/boot'
      @key_name = 'boot.key'
      @bootloader = true
      @mount = '/boot'
      @luks = options[:luks_name]
      @luks_name = "boot-#{@luks}"
      @command_args = "--type #{@luks_type}"
    end
  end

  # Root can decrypt the /home or other devs
  class Root < Main
    def initialize(disk, options)
      super
      @luks_type = 'luks2'
      @key_dir = '/boot'
      @key_name = 'root.key'
      @luks = options[:luks_name]
      @luks_name = "root-#{@luks}"
      @mount = '/'
      @command_args = "--type #{@luks_type}"
      @bootloader = false
    end
  end

  # define home partition for luks
  class Home < Main
    def initialize(disk, options)
      super
      @luks_type = 'luks2'
      @key_dir = '/root/keys'
      @key_name = 'home.key'
      @mount = '/home'
      @command_args = "--type #{@luks_type}"
      @luks = options[:luks_name]
      @luks_name = "home-#{@luks}"
      @bootloader = false
    end
  end
end
