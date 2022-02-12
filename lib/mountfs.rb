# frozen_string_literal: true

require 'nito'

module MountFs
  class Minimal
    include NiTo

    def initialize(devs, options)
      @efi = devs[:efi] ||= nil
      @boot = devs[:boot] ||= nil
      @swap = devs[:swap] ||= nil
      @root = devs[:root] ||= nil
      @home = devs[:home] ||= nil
      @mountpoint = options[:mountpoint]
      x
    end

    protected

    def x
      mount_root
      mount_efi
      mount_boot
      mount_swap
      mount_home
    end

    def mount_root
      mount "/dev/#{@root}", @mountpoint
    end

    def mount_efi
      @efi || return

      mount "/dev/#{@efi}", "#{@mountpoint}/efi"
    end

    def mount_boot
      @boot || return

      mount "/dev/#{@root}", "#{@mountpoint}/boot"
    end

    def mount_swap
      @swap || return

      grep?('/proc/swaps', "/dev/#{@swap}") && return

      swapon "/dev/#{@swap}"
    end

    def mount_home
      @home || return

      mount "/dev/#{@home}", "#{@mountpoint}/home"
    end

    private

    def swapon(path)
      Getch::Command.new('swapon', path)
    end
  end

  class Lvm < Minimal
    def initialize(devs, options)
      @vg = options[:vg_name]
      super
    end

    def mount_root
      mount "/dev/#{@vg}/root", @mountpoint
    end

    def mount_swap
      dm = Getch::Helpers.get_dm "#{@vg0}-swap"

      grep?('/proc/swaps', "/dev/#{dm}") && return

      swapon "/dev/#{@vg}/swap"
    end

    def mount_home
      mount "/dev/#{@vg}/home", "#{@mountpoint}/home"
    end
  end

  class Encrypt < Minimal
    def initialize(devs, options)
      @luks = options[:luks_name]
      super
    end

    def mount_root
      umount "/dev/mapper/boot-#{@luks}"
      mount "/dev/mapper/root-#{@luks}", @mountpoint
    end

    def mount_boot
      mount "/dev/mapper/boot-#{@luks}", "#{@mountpoint}/boot"
    end

    def mount_swap
    end

    def mount_home
      @home || return

      mount "/dev/mapper/home-#{@luks}", "#{@mountpoint}/home"
    end
  end

  class Hybrid < Encrypt
    def initialize(devs, options)
      @vg = options[:vg_name]
      super
    end

    def mount_root
      umount "/dev/mapper/boot-#{@luks}"
      mount "/dev/#{@vg}/root", @mountpoint
    end

    def mount_boot
      mount "/dev/mapper/boot-#{@luks}", "#{@mountpoint}/boot"
    end

    def mount_home
      mount "/dev/#{@vg}/home", "#{@mountpoint}/home"
    end
  end

  class Zfs < Minimal
    def initialize(devs, options)
      @zfs = options[:zfs_name]
      @os = options[:os]
      super
    end

    # Root should be alrealy mounted
    def mount_root
    end

    def mount_boot
      @boot || return

      Getch::Command.new("zfs mount b#{@zfs}/BOOT/#{@os}")
    end

    def mount_home
    end
  end
end
