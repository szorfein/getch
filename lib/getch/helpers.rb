require 'open-uri'
require 'open3'
require 'fileutils'

module Helpers
  def self.efi?
    Dir.exist? '/sys/firmware/efi/efivars'
  end

  def self.get_file_online(url, dest)
    URI.open(url) do |l|
      File.open(dest, "wb") do |f|
        f.write(l.read)
      end
    end
  end

  def self.exec_or_die(cmd)
    _, stderr, status = Open3.capture3(cmd)
    unless status.success?
      raise "Problem running #{cmd}, stderr was:\n#{stderr}"
    end
  end

  def self.create_dir(path, perm = 0755)
    FileUtils.mkdir_p path, mode: perm if ! Dir.exist?(path)
  end

  def self.add_file(path, content = '')
    File.write path, content if ! File.exist? path
  end

  def self.mkdir(dir)
    FileUtils.mkdir_p dir if ! Dir.exist? dir
  end

  def self.touch(file)
    File.write file, '' if ! File.exist? file
  end

  def self.cp(src, dest)
    raise "Src file #{src} no found" unless File.exist? src
    FileUtils.cp(src, dest)
  end

  def self.grep?(file, regex)
    is_found = false
    return is_found if ! File.exist? file
    File.open(file) do |f|
      f.each do |line|
        is_found = true if line.match(regex)
      end
    end
    is_found
  end

  def self.sys(cmd)
    system(cmd)
    unless $?.success?
      raise "Error with #{cmd}"
    end
  end

  def self.partuuid(dev)
    `lsblk -o PARTUUID #{dev}`.match(/[\w]+-[\w]+-[\w]+-[\w]+-[\w]+/)
  end

  def self.uuid(dev)
    Dir.glob("/dev/disk/by-uuid/*").each { |f|
      if File.readlink(f).match(/#{dev}/)
        return f.delete_prefix("/dev/disk/by-uuid/")
      end
    }
  end

  # Used with ZFS for the pool name
  def self.pool_id(dev)
    if dev.match(/[0-9]/)
      sleep 1
      `lsblk -o PARTUUID #{dev}`.delete("\n").delete("PARTUUID").match(/[\w]{5}/)
    else
      puts "Please, enter a pool name"
      while true
        print "\n> "
        value = gets
        if value.match(/[a-z]{4,20}/)
          return value
        end
        puts "Bad name, you enter: #{value}"
        puts "Valid pool name use character only, between 4-20."
      end
    end
  end

  module Void
    def command(args)
      print " => Exec: #{args}..."
      cmd = "chroot #{Getch::MOUNTPOINT} /bin/bash -c \"#{args}\""
      _, stderr, status = Open3.capture3(cmd)
      if status.success? then
        puts "\s[OK]"
        return
      end
      raise "\n[-] Fail cmd #{args} - #{stderr}."
    end

    def command_output(args)
      print " => Exec: #{args}..."
      cmd = "chroot #{Getch::MOUNTPOINT} /bin/bash -c \"#{args}\""
      Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
        puts
        while line = stdout_err.gets
          puts line
        end

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
      File.open(file).each { |line|
        return true if line.match(/#{text}/)
      }
      return false
    end

    # Used only when need password
    def chroot(cmd)
      if !system("chroot", Getch::MOUNTPOINT, "/bin/bash", "-c", cmd)
        raise "[-] Error with: #{cmd}"
      end
    end
  end

  module Cryptsetup
    def encrypt(dev)
      raise "No device #{dev}" unless File.exist? dev
      puts " => Encrypting device #{dev}..."
      if Helpers::efi? && Getch::OPTIONS[:os] == 'gentoo'
        Helpers::sys("cryptsetup luksFormat --type luks #{dev}")
      else
        Helpers::sys("cryptsetup luksFormat --type luks1 #{dev}")
      end
    end

    def open_crypt(dev, map_name)
      raise "No device #{dev}" unless File.exist? dev
      puts " => Opening encrypted device #{dev}..."
      if Helpers::efi? && Getch::OPTIONS[:os] == 'gentoo'
        Helpers::sys("cryptsetup open --type luks #{dev} #{map_name}")
      else
        Helpers::sys("cryptsetup open --type luks1 #{dev} #{map_name}")
      end
    end
  end
end
