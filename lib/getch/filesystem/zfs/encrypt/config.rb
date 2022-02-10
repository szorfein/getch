# frozen_string_literal: true

require 'fstab'
require 'dracut'

module Getch
  module FileSystem
    module Zfs
      module Encrypt
        class Config
          def initialize
            x
          end

          private

          def x
            Fstab::Zfs.new(DEVS, OPTIONS).generate
            Dracut::Zfs.new(DEVS, OPTIONS).generate
          end

          def crypttab
            datas = [
              "cryptswap PARTUUID=#{@partuuid_swap} /dev/urandom swap,discard,cipher=aes-xts-plain64:sha256,size=512"
            ]
            File.write("#{MOUNTPOINT}/etc/crypttab", datas.join("\n"))
          end
        end
      end
    end
  end
end
