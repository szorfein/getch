# frozen_string_literal: true

require 'nito'
require 'getch/log'
require 'getch/command'

module Luks
  def search_uuid(dev)
    Dir.glob('/dev/disk/by-uuid/*').each do |f|
      if File.readlink(f).match(/#{dev}$/)
        return f.delete_prefix('/dev/disk/by-uuid/')
      end
    end
    raise "No uuid found for #{dev}"
  end

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
      @bs = get_bs
    end

    def encrypt
      args = @luks_type == 'luks2' ? "#{@command_args} --sector-size #{@bs}" : @command_args
      @log.info "Encrypting #{@luks_name} > #{@disk}...\n"
      cmd_crypt 'cryptsetup', 'luksFormat', args, "/dev/#{@disk}"
    end

    def encrypt_with_key
      make_key
      args = @luks_type == 'luks2' ?
        "#{@command_args} -q --sector-size #{@bs} -d #{@full_key_path}" :
        "#{@command_args} -q -d #{@full_key_path}"
      @log.info "Encrypting #{@luks_name} with #{@full_key_path}...\n"
      cmd_crypt 'cryptsetup', 'luksFormat', args, "/dev/#{@disk}"
    end

    def open
      return if File.exist? "/dev/mapper/#{@luks_name}"

      @log.info "Opening #{@luks_name} > #{@disk}...\n"
      cmd_crypt 'cryptsetup', 'open', @command_args, "/dev/#{@disk}", @luks_name
      unless File.exist? "/dev/mapper/#{@luks_name}"
        raise "No dev /dev/mapper/#{@luks_name}, open it first..."
      end
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

    def gen_datas
    end

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
      sh 'mkfs.ext4', '-F', '-b', @bs, "/dev/mapper/#{@luks_name}"
    end

    # https://wiki.archlinux.org/title/Advanced_Format#File_systems
    def format_xfs
      @log.info "Formating disk with #{@format}...\n"
      sh 'mkfs.xfs', '-f', '-s', "size=#{@bs}", "/dev/mapper/#{@luks_name}"
    end

    def config
      @key_path = "#{@key_dir}/#{@key_name}"
      uuid = search_uuid @disk
      @log.info 'Writing configs...'

      puts " >> Writing #{@mountpoint}/etc/crypttab..."
      line = "#{@luks_name} UUID=#{uuid} #{@key_path} luks"
      echo_a "#{@mountpoint}/etc/crypttab", line

      puts " >> Writing #{@mountpoint}/etc/fstab..."
      line = "/dev/mapper/#{@luks_name} #{@mount} #{@format} defaults 0 0"
      echo_a "#{@mountpoint}/etc/fstab", line

      config_grub
      config_dracut
    end

    def config_grub
      return unless @bootloader

      if File.exist? "#{@mountpoint}/etc/default/grub"
        @log.info 'Writing to /etc/default/grub...'
        line = 'GRUB_ENABLE_CRYPTODISK=y'
        echo_a "#{@mountpoint}/etc/default/grub", line
        @log.result_ok
      end
    end

    def config_dracut
      return unless @bootloader

      @key_path = "#{@key_dir}/#{@key_name}"
      if Dir.exist? "#{@mountpoint}/etc/dracut.conf.d"
        @log.info "Writing to /etc/dracut.conf.d/#{@luks_name}.conf..."
        line = "install_items+=\" #{@key_path} /etc/crypttab \""
        File.write "#{@mountpoint}/etc/dracut.conf.d/#{@luks_name}.conf", "#{line}\n"
        @log.result_ok
      end
    end

    def perm
      @key_path = "#{@key_dir}/#{@key_name}"
      @full_key_path = "#{@mountpoint}#{@key_path}"
      @log.info "Enforcing permission on #{@full_key_path}..."
      File.chmod 0400, "#{@mountpoint}#{@key_dir}"
      File.chmod 0000, @full_key_path
      File.chown 0, 0, @full_key_path
      @log.result_ok
    end

    private

    def get_bs
      @disk || @log.fatal("No disk for #{@luks_name}.")

      sh 'blockdev', '--getpbsz', "/dev/#{@disk}"
    end

    def cmd_crypt_raw(*args)
      system args.join(' ')
      return if $?.exitstatus == 0

      @log.dbg args.join(' ')
      @log.dbg $?
      @log.fatal 'die'
    end

    def cmd_crypt(*args)
      cmd_crypt_raw args
    rescue => e
      @log.fatal e
    end

    def sh(*args)
      Getch::Command.new(args)
    end
  end

  # Boot can decrypt the root (/)
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
