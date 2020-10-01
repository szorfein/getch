require 'open-uri'
require 'open3'
require 'fileutils'
require_relative 'command'

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

  def self.emerge(pkgs, path)
    cmd = "chroot #{path} /bin/bash -c \"
      source /etc/profile
      emerge --changed-use #{pkgs}
    \""
    Getch::Command.new(cmd).run!
  end

  def self.run_chroot(cmd, path)
    script = "chroot #{path} /bin/bash -c \"
      source /etc/profile
      #{cmd}
    \""
    Getch::Command.new(script).run!
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
end
