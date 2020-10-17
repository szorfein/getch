module Getch
  module FileSystem
  end
end

require_relative 'filesystem/clean'

require_relative 'filesystem/ext4'
require_relative 'filesystem/lvm'
require_relative 'filesystem/zfs'
