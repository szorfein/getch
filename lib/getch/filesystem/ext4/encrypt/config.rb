# frozen_string_literal: true

require 'fileutils'
require 'nito'
require 'fstab'

module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Config < Getch::FileSystem::Ext4::Encrypt::Device
          include NiTo

          def initialize
            super
            gen_uuid
            @root_dir = OPTIONS[:mountpoint]
            move_secret_keys
            crypttab
          end

          def fstab
            devs = { esp: @dev_esp, boot: @dev_boot, swap: @dev_swap, root: @dev_root, home: @dev_home }
            Fstab::Encrypt.new(devs, OPTIONS).generate
          end

          def cmdline
            conf = "#{MOUNTPOINT}/etc/dracut.conf.d/cmdline.conf"
            line = "rd.luks.uuid=#{@uuid_dev_root} rd.vconsole.keymap=#{OPTIONS[:keymap]} rw"
            File.write conf, "kernel_cmdline=\"#{line}\"\n"
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

          def gen_uuid
            @partuuid_swap = Helpers.partuuid(@dev_swap)
            @uuid_dev_root = `lsblk -d -o "UUID" #{@dev_root} | tail -1`.chomp() if @dev_root
            @uuid_home = `lsblk -d -o "UUID" #{@dev_home} | tail -1`.chomp() if @luks_home
          end

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
