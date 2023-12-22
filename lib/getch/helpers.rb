# frozen_string_literal: true

require 'open-uri'
require 'open3'
require 'fileutils'
require 'nito'

module Getch
  # Various helpers function defined here
  module Helpers
    def self.efi?
      Dir.exist? '/sys/firmware/efi/efivars'
    end

    def self.systemd?
      Dir.exist? "#{OPTIONS[:mountpoint]}/etc/systemd"
    end

    def self.openrc?
      File.exist? "#{OPTIONS[:mountpoint]}/etc/conf.d/keymaps"
    end

    def self.runit?
      Dir.exist? "#{OPTIONS[:mountpoint]}/etc/runit"
    end

    def self.grub?
      File.exist? "#{OPTIONS[:mountpoint]}/etc/default/grub"
    end

    # if systemd without encryption
    def self.systemd_minimal?
      systemd? && efi? && !OPTIONS[:encrypt]
    end

    def self.get_file_online(url, dest)
      URI.open(url) do |l|
        File.open(dest, 'wb') { |f| f.write(l.read) }
      end
    rescue Net::OpenTimeout => e
      abort "DNS error #{e}"
    end

    def self.exec_or_die(cmd)
      _, stderr, status = Open3.capture3(cmd)
      return if status.success?

      abort "Problem running #{cmd}, stderr was:\n#{stderr}"
    end

    def self.sys(cmd)
      system(cmd)
      $?.success? || abort("Error with #{cmd}")
    end

    def self.partuuid(dev)
      `lsblk -o PARTUUID #{dev}`.match(/\w+-\w+-\w+-\w+-\w+/)
    end

    def self.uuid(dev)
      Dir.glob('/dev/disk/by-uuid/*').each do |f|
        p = File.readlink(f)
        return f.delete_prefix('/dev/disk/by-uuid/') if p.match?(/#{dev}/)
      end
      Log.new.fatal("UUID on #{dev} is no found")
    end

    def self.id(dev)
      Dir.glob('/dev/disk/by-id/*').each do |f|
        p = File.readlink(f)
        return f.delete_prefix('/dev/disk/by-id/') if p.match?(/#{dev}/)
      end
      Log.new.fatal("ID on #{dev} is no found")
    end

    def self.get_dm(name)
      Dir.glob('/dev/mapper/*').each do |f|
        if f =~ /#{name}/ && f != '/dev/mapper/control'
          return File.readlink(f).tr('../', '')
        end
      end
      Log.new.fatal("Dm for #{name} is no found")
    end

    # Used by ZFS for the pool creation
    # sleep is necessary here at least the first time
    def self.get_id(dev)
      sleep 3
      Dir.glob('/dev/disk/by-id/*').each do |f|
        p = File.readlink(f)
        return f.delete_prefix('/dev/disk/by-id/') if p.match?(/#{dev}/)
      end
      Log.new.fatal("ID on #{dev} is no found")
    end

    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base
    def self.mount_all
      dest = OPTIONS[:mountpoint]
      NiTo.mount '--types proc /proc', "#{dest}/proc"
      %w[dev sys run].each do |d|
        NiTo.mount '--rbind', "/#{d}", "#{dest}/#{d}"
        NiTo.mount '--make-rslave', "#{dest}/#{d}"
      end
    end

    def self.get_memory
      mem = nil
      File.open('/proc/meminfo').each do |l|
        t = l.split(' ') if l =~ /memtotal/i
        t && mem = t[1]
      end
      mem || Log.new.fatal('get_memory - failed to get memory')

      mem += 'K'
    end

    # get the sector size of a disk
    def self.get_bs(path)
      cmd = Getch::Command.new('blockdev', '--getpbsz', path)
      cmd.res
    end

    # Helpers specific to void
    module Void
      def command_output(args)
        print " => Exec: #{args}..."
        cmd = "chroot #{Getch::MOUNTPOINT} /bin/bash -c \"#{args}\""
        Open3.popen2e(cmd) do |_, stdout_err, wait_thr|
          puts
          stdout_err.each { |l| puts l }

          exit_status = wait_thr.value
          raise("\n[-] Fail cmd #{args} - #{stdout_err}.") unless exit_status.success?
        end
      end

      # Used only when need password
      def chroot(cmd)
        return if system('chroot', Getch::MOUNTPOINT, '/bin/bash', '-c', cmd)

        raise "[-] Error with: #{cmd}"
      end

      def s_uuid(dev)
        device = dev.delete_prefix('/dev/')
        Dir.glob('/dev/disk/by-partuuid/*').each do |f|
          link = File.readlink(f)
          return f.delete_prefix('/dev/disk/by-partuuid/') if link.match(/#{device}$/)
        end
      end

      def line_fstab(dev, rest)
        conf = "#{Getch::MOUNTPOINT}/etc/fstab"
        device = s_uuid(dev)
        raise "No partuuid for #{dev} #{device}" unless device
        raise "Bad partuuid for #{dev} #{device}" if device.is_a?(Array)

        add_line(conf, "PARTUUID=#{device} #{rest}")
      end
    end
  end
end
