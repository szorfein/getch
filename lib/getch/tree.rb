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
        true => {
          ext4: FileSystem::Ext4::Encrypt,
          lvm: FileSystem::Lvm::Encrypt,
          zfs: FileSystem::Zfs::Encrypt
        },
        false => {
          ext4: FileSystem::Ext4,
          lvm: FileSystem::Lvm,
          zfs: FileSystem::Zfs,
        }
      }.freeze

      def initialize
        @encrypt = OPTIONS[:encrypt]
        @fs = OPTIONS[:fs]
        @log = Log.new
      end

      def select
        FS_TREE[@encrypt][@fs.to_sym] || @log.fatal('Error in FS_TREE')
      end
    end
  end
end
