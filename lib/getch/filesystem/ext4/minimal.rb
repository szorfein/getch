# frozen_string_literal: true

module Getch
  module FileSystem
    module Ext4
      module Minimal
      end
    end
  end
end

require_relative 'minimal/device'
require_relative 'minimal/partition'
require_relative 'minimal/format'
require_relative 'minimal/mount'
require_relative 'minimal/deps'
require_relative 'minimal/config'
