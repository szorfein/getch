# frozen_string_literal: true

module Getch
  module FileSystem
  end
end

require_relative 'filesystem/partition'

require_relative 'filesystem/ext4'
require_relative 'filesystem/zfs'
