# frozen_string_literal: true

require 'fileutils'

# uNix Tools like mkdir, mount in Ruby code
module NiTo
  module_function

  def mkdir(path, perm = 0755)
    return if Dir.exist? path

    FileUtils.mkdir_p path, mode: perm
  end
end
