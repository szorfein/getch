# frozen_string_literal: true

module Getch
  # All class to install Voidlinux
  module Void
  end
end

require_relative 'void/tarball'
require_relative 'void/pre_config'
require_relative 'void/update'
require_relative 'void/post_config'
require_relative 'void/terraform'
require_relative 'void/services'
require_relative 'void/bootloader'
require_relative 'void/finalize'
