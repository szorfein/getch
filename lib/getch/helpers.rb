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
end
