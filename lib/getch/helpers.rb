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
    `lsblk -do UUID #{dev}`.match(/[\w]+-[\w]+-[\w]+-[\w]+-[\w]+/)
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
end
