# frozen_string_literal: true

require 'open-uri'
require 'open3'
require 'fileutils'

module Getch
  module Helpers
    def self.efi?
      Dir.exist? '/sys/firmware/efi/efivars'
    end

    def self.get_file_online(url, dest)
      URI.open(url) do |l|
        File.open(dest, "wb") { |f| f.write(l.read) }
      end
    end

    def self.exec_or_die(cmd)
      _, stderr, status = Open3.capture3(cmd)
      unless status.success?
        raise "Problem running #{cmd}, stderr was:\n#{stderr}"
      end
    end

    def self.create_dir(path, perm = 0755)
      FileUtils.mkdir_p path, mode: perm unless Dir.exist? path
    end

    def self.add_file(path, content = '')
      File.write path, content unless File.exist? path
    end

    def self.mkdir(dir)
      FileUtils.mkdir_p dir unless Dir.exist? dir
    end

    def self.touch(file)
      File.write file, '' unless File.exist? file
    end

    def self.cp(src, dest)
      raise "Src file #{src} no found" unless File.exist? src

      FileUtils.cp(src, dest)
    end

    def self.grep?(file, regex)
      is_found = false
      return is_found unless File.exist? file
      File.open(file) do |f|
        f.each { |l| is_found = true if l.match(regex) }
      end
      is_found
    end

    def self.sys(cmd)
      system(cmd)
      raise "Error with #{cmd}" unless $?.success?
    end

    def self.partuuid(dev)
      `lsblk -o PARTUUID #{dev}`.match(/\w+-\w+-\w+-\w+-\w+/)
    end

    def self.uuid(dev)
      Dir.glob('/dev/disk/by-uuid/*').each do |f|
        if File.readlink(f).match(/#{dev}/)
          return f.delete_prefix('/dev/disk/by-uuid/')
        end
      end
    end

    # Used with ZFS for the pool name
    def self.pool_id(dev)
      if dev.match(/[0-9]/)
        sleep 1
        `lsblk -o PARTUUID #{dev}`.delete("\n").delete('PARTUUID').match(/\w{5}/)
      else
        puts 'Please, enter a pool name'
        while true
          print "\n> "
          value = gets
          if value.match(/[a-z]{4,20}/)
            return value
          end
          puts "Bad name, you enter: #{value}"
          puts 'Valid pool name use character only, between 4-20.'
        end
      end
    end

    module Void
      def command(args)
        print " => Exec: #{args}..."
        cmd = "chroot #{Getch::MOUNTPOINT} /bin/bash -c \"#{args}\""
        _, stderr, status = Open3.capture3(cmd)
        if status.success?
          puts "\s[OK]"
          return
        end
        raise "\n[-] Fail cmd #{args} - #{stderr}."
      end

      def command_output(args)
        print " => Exec: #{args}..."
        cmd = "chroot #{Getch::MOUNTPOINT} /bin/bash -c \"#{args}\""
        Open3.popen2e(cmd) do |_, stdout_err, wait_thr|
          puts
          stdout_err.each { |l| puts l }

          exit_status = wait_thr.value
          unless exit_status.success?
            raise "\n[-] Fail cmd #{args} - #{stdout_err}."
          end
        end
      end

      def add_line(file, line)
        raise "No file #{file} found !" unless File.exist? file

        File.write(file, "#{line}\n", mode: 'a')
      end

      def search(file, text)
        File.open(file).each do |line|
          return true if line.match(/#{text}/)
        end
        false
      end

      # Used only when need password
      def chroot(cmd)
        unless system('chroot', Getch::MOUNTPOINT, '/bin/bash', '-c', cmd)
          raise "[-] Error with: #{cmd}"
        end
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
        raise "Bad partuuid for #{dev} #{device}" if device.kind_of? Array

        add_line(conf, "PARTUUID=#{device} #{rest}")
      end

      def grub_cmdline(*args)
        conf = "#{Getch::MOUNTPOINT}/etc/default/grub"
        list = args.join(' ')
        secs = "GRUB_CMDLINE_LINUX=\"#{list} init_on_alloc=1 init_on_free=1"
        secs += ' slab_nomerge pti=on slub_debug=ZF vsyscall=none"'
        raise 'No default/grub found' unless File.exist? conf

        unless search(conf, 'GRUB_CMDLINE_LINUX=')
          File.write(conf, "#{secs}\n", mode: 'a')
        end
      end
    end

    module Cryptsetup
      def encrypt(dev)
        raise "No device #{dev}" unless File.exist? dev

        puts " => Encrypting device #{dev}..."
        if Helpers.efi? && Getch::OPTIONS[:os] == 'gentoo'
          Helpers.sys("cryptsetup luksFormat --type luks #{dev}")
        else
          Helpers.sys("cryptsetup luksFormat --type luks1 #{dev}")
        end
      end

      def open_crypt(dev, map_name)
        raise "No device #{dev}" unless File.exist? dev

        puts " => Opening encrypted device #{dev}..."
        if Helpers.efi? && Getch::OPTIONS[:os] == 'gentoo'
          Helpers.sys("cryptsetup open --type luks #{dev} #{map_name}")
        else
          Helpers.sys("cryptsetup open --type luks1 #{dev} #{map_name}")
        end
      end
    end
  end
end
