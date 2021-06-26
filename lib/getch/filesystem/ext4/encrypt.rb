module Getch
  module FileSystem
    module Ext4
      module Encrypt
      end
    end
  end
end

require_relative 'encrypt/device'
require_relative 'encrypt/partition'
require_relative 'encrypt/format'
require_relative 'encrypt/mount'
require_relative 'encrypt/config'
require_relative 'encrypt/deps'
require_relative 'encrypt/void'
