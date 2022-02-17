# frozen_string_literal: true

require_relative 'gentoo/sources'
require_relative 'gentoo/use'
require_relative 'gentoo/use_flag'

module Getch
  module Gentoo
  end
end

require_relative 'gentoo/tarball'
require_relative 'gentoo/pre_config'
require_relative 'gentoo/update'
require_relative 'gentoo/post_config'
require_relative 'gentoo/terraform'
require_relative 'gentoo/services'
require_relative 'gentoo/bootloader'
require_relative 'gentoo/finalize'
