# frozen_string_literal: true

require 'luks'

class CryptSetup
  def initialize(devs, options)
    @boot = devs[:boot]
    @root = devs[:root]
    @home = devs[:home]
    @options = options
    @fs = options[:fs] ||= 'ext4'
    @mountpoint = options[:mountpoint] ||= '/mnt/getch'
  end

  def format
    format_boot
    format_root
    format_home
  end

  def keys
    add_boot_key
    add_root_key
    add_home_key
  end

  protected

  def format_boot
    luks = Luks::Boot.new(@boot, @options)
    luks.encrypt
    luks.open
    luks.format
    luks.mount
  end

  # if boot and root are on the same device, we encrypt root with a key
  def format_root
    if @boot.split(/[0-9]/) == @root.split(/[0-9]/)
      root_with_key
    else
      root_with_pass
    end
  end

  def format_home
    @home || return

    home_with_pass
  end

  def add_boot_key
    luks = Luks::Boot.new(@boot, @options)
    luks.external_key
  end

  # Alrealy used key if they have same disk
  def add_root_key
    return if @boot.split(/[0-9]/) == @root.split(/[0-9]/)

    luks = Luks::Root.new(@root, @options)
    luks.external_key
  end

  def add_home_key
    @home || return

    luks = Luks::Home.new(@home, @options)
    luks.external_key
  end

  private

  def root_with_key
    luks = Luks::Root.new(@root, @options)
    luks.encrypt_with_key
    luks.open_with_key
  end

  def root_with_pass
    luks = CryptSetup::Root.new(@root, @options)
    luks.encrypt
    luks.open
  end

  def home_with_pass
    luks = CryptSetup::Home.new(@home, @options)
    luks.encrypt
    luks.open
  end
end
