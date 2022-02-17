# frozen_string_literal: true

module Getch
  module Tree
    class Os

      OS_TREE = {
        gentoo: Gentoo,
        void: Void
      }.freeze

      def initialize
        @os = OPTIONS[:os]
        @log = Log.new
      end

      def select
        OS_TREE[@os.to_sym] || @log.fatal('OS no found')
      end
    end
    class FS

      FS_TREE = {
        true => { # + encrypt
          true => { # + lvm
            ext4: FileSystem::Ext4::Hybrid,
          },
          false => { # - lvm
            ext4: FileSystem::Ext4::Encrypt,
            zfs: FileSystem::Zfs::Encrypt
          },
        },
        false => { # - encrypt
          true => { # + lvm
            ext4: FileSystem::Ext4::Lvm,
          },
          false => { # - lvm
            ext4: FileSystem::Ext4::Minimal,
            zfs: FileSystem::Zfs::Minimal,
          },
        }
      }.freeze

      def initialize
        @encrypt = OPTIONS[:encrypt]
        @lvm = OPTIONS[:lvm]
        @fs = OPTIONS[:fs]
        @log = Log.new
      end

      def select
        FS_TREE[@encrypt][@lvm][@fs.to_sym] || @log.fatal('Error in FS_TREE or no comptatible options')
      end
    end
  end
end
