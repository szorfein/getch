# frozen_string_literal: true

require 'fileutils'
require 'nito'
require 'fstab'
require 'dracut'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Config < Getch::FileSystem::Ext4::Encrypt::Device
          include NiTo

          def initialize
            super
            @root_dir = OPTIONS[:mountpoint]
            @devs = { esp: @dev_esp, boot: @dev_boot, swap: @dev_swap, root: @dev_root, home: @dev_home }
            move_secret_keys
            crypttab
            x
          end

          protected

          def x
            Fstab::Encrypt.new(@devs, OPTIONS).generate
            Dracut::Encrypt.new(@devs, OPTIONS).generate
            grub
          end

          def crypttab
            home = @home_disk ? "crypthome UUID=#{@uuid_home} /root/secretkeys/crypto_keyfile.bin luks" : ''
            datas = [
              "cryptswap PARTUUID=#{@partuuid_swap} /dev/urandom swap,cipher=aes-xts-plain64:sha256,size=512",
              home
            ]
            File.write("#{@root_dir}/etc/crypttab", datas.join("\n"))
          end

          def grub
            return unless File.exist? "#{@root_dir}/etc/default/grub"

            file = "#{@root_dir}/etc/default/grub"
            echo_a file, 'GRUB_ENABLE_CRYPTODISK=y'
          end

          private

          def move_secret_keys
            return unless @luks_home

            puts 'Moving secret keys'
            keys_path = "#{@root_dir}/root/secretkeys"
            FileUtils.mv('/root/secretkeys', keys_path) unless Dir.exist? keys_path
          end
        end
      end
    end
  end
end
