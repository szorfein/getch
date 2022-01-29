# frozen_string_literal: true

require 'fileutils'
require 'open3'
require_relative 'getch/log'
require_relative 'getch/command'

# uNix Tools like mkdir, mount in Ruby code
module NiTo
  module_function

  def mkdir(path, perm = 0755)
    return if Dir.exist? path

    FileUtils.mkdir_p path, mode: perm
  end

  def grep?(file, search)
    is_found = false
    return is_found unless File.exist? file

    File.open(file).each do |l|
      is_found = true if l =~ /#{search}/
    end
    is_found
  end

  def rm(file)
    File.exist?(file) && File.delete(file)
  end

  def umount(dir)
    return unless mount? dir

    Getch::Command.new('umount', dir).run!
  end

  def mount?(dir)
    res = false
    File.open('/proc/mounts').each do |l|
      res = true if l =~ /#{dir}/
    end
    res
  end

  # Like echo 'content' > to_file
  def echo(file, content)
    File.write file, "#{content}\n", mode: 'w'
  end

  # Like echo 'content' >> to_file
  def echo_a(file, content)
    File.write file, "#{content}\n", mode: 'a' unless grep? file, content
  end

  def cp(src, dest)
    FileUtils.cp src, dest
  end

  # create a void file
  def touch(file)
    File.write file, '' unless File.exist? file
  end

  def sh(*args)
    log = Log.new
    Open3.popen3 args.join(' ') do |_, stdout, stderr, wait_thr|
      if wait_thr.value.success?
        log.info_res 'Ok'
        return stdout.read.chomp
      end
      puts
      log.dbg args.join(' ') + "\nEXIT:#{wait_thr.value}"
      log.dbg "STDERR:#{stderr.read}"
      log.dbg "STDOUT:#{stdout.read}"
      log.fatal 'Die'
    end
  end
end
