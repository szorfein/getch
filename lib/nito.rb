# frozen_string_literal: true

require 'fileutils'
require 'open3'
require_relative 'getch/log'

# uNix Tools like mkdir, mount in Ruby code
module NiTo
  module_function

  def mkdir(path, perm = 0755)
    return if Dir.exist? path

    FileUtils.mkdir_p path, mode: perm
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
