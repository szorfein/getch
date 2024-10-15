# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tempfile'
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

    Getch::Command.new('umount', dir)
  end

  # Mount, accept *args, the last argument should be the destination
  # e.g: mount '--types proc', '/proc', '/mnt/getch/proc'
  def mount(*args)
    return if mount? args.last

    mkdir args.last
    Getch::Command.new('mount', args.join(' '))
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
    File.write(file, "#{content}\n")
  end

  # Like echo 'content' >> to_file
  def echo_a(file, content)
    File.write(file, "#{content}\n", mode: 'a') unless grep? file, content
  end

  def cp(src, dest)
    FileUtils.cp src, dest
  end

  def mv(src, dest)
    FileUtils.mv src, dest
  end

  # create a void file
  def touch(file)
    File.write(file, '') unless File.exist? file
  end

  # Like sed -i /old:new/ file
  def sed(file, regex, change)
    tmp_file = Tempfile.new
    File.open(file).each do |l|
      if l.match(regex)
        echo_a tmp_file, change
      else
        File.write tmp_file, l, mode: 'a'
      end
    end
    cp tmp_file, file
  end

  def search_proc_swaps(path)
    found = nil
    File.open('/proc/swaps').each do |l|
      if l =~ /#{path}/
        found = l.split(' ')
      end
    end
    found
  end

  def swapoff(dev)
    return unless grep? '/proc/swaps', dev

    found = search_proc_swaps(dev)
    found ?
      Getch::Command.new('swapoff', found[0]) :
      return
  end

  def swapoff_dm(name)
    dm = Getch::Helpers.get_dm name
    dm || return

    found = search_proc_swaps(dm)
    found ?
      Getch::Command.new('swapoff', found[0]) :
      return
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
