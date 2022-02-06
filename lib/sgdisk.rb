# frozen_string_literal: true

require 'getch/command'
require 'getch/helpers'

module Sgdisk
  class Root
    def initialize(devs)
      @gpt = devs[:gpt] ||= nil
      @efi = devs[:efi] ||= nil
      @boot = devs[:boot] ||= nil
      @swap = devs[:swap] ||= nil
      @root = devs[:root] ||= nil
      @home = devs[:home] ||= nil
      load_codes
      x
    end

    protected

    def x
      make_gpt
      make_efi
      make_boot
      make_swap
      make_root
      make_home
    end

    def make_gpt
      @gpt || return

      partition @gpt, @gpt_code, '1MiB:+1MiB'
    end

    def make_efi
      @efi || return

      partition @efi, @efi_code, '1M:+260M'
    end

    def make_boot
      @boot || return

      partition @boot, @boot_code, '0:+256MiB'
    end

    def make_swap
      @swap || return

      mem = Getch::Helpers.get_memory
      partition @swap, @swap_code, "0:+#{mem}"
    end

    # Align the end
    # https://unix.stackexchange.com/questions/588930/sgdisk-force-alignment-of-end-sector
    # https://gitlab.com/cryptsetup/cryptsetup/-/issues/585
    def make_root
      @root || return

      return unless @root =~ /[0-9]/

      finish = end_sector @root
      partition @root, @root_code, "0:#{finish}"
    end

    def make_home
      @home || return

      return unless @home =~ /[0-9]/

      finish = end_sector @home
      partition @home, @home_code, "0:#{finish}"
    end

    private

    # sgdisk -L
    def load_codes
      @gpt_code  = 'ef02'
      @efi_code  = 'ef00'
      @boot_code = '8300'
      @swap_code = '8200'
      @root_code = '8304'
      @home_code = '8302'
    end

    # e.g: partition sda1, 'ef02', '1Mib:+1MiB'
    def partition(disk, code, sectors)
      d = disk[/^[a-z]+/]
      p = disk[/[0-9]{1}$/]
      args = "-n#{p}:#{sectors} -t#{p}:#{code} /dev/#{d}"

      Getch::Command.new('sgdisk', args)
    end

    def end_sector(dev)
      disk = dev[/^[a-z]+/]
      cmd = Getch::Command.new("sgdisk -E /dev/#{disk}")
      end_position = cmd.res.to_i
      ( end_position - ( end_position + 1 ) % 2048 )
    end
  end

  class Ext4 < Root
  end

  class Lvm < Root
    def load_codes
      super
      @root_code = '8e00'
      @home_code = '8e00'
    end
  end
end
