# frozen_string_literal: true

module Getch
  module FileSystem
    module Zfs
      module Minimal
        def self.end
        end
      end
    end
  end
end

require_relative 'minimal/device'
require_relative 'minimal/partition'
require_relative 'minimal/format'
require_relative 'minimal/mount'
require_relative 'minimal/config'
require_relative 'minimal/deps'
