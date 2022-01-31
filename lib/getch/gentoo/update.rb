# frozen_string_literal: true

require 'nito'

module Getch
  module Gentoo
    class Update
      include NiTo

      def initialize
        @log = Log.new
        x
      end

      protected

      def x
        sync
        update
      end

      private

      def sync
        gentoo_conf = "#{OPTIONS[:mountpoint]}/etc/portage/repos.conf/gentoo.conf"
        @log.info "Synchronize index, please waiting...\n"
        ChrootOutput.new('emaint sync --auto')
        sed gentoo_conf, /^sync-type/, 'sync-type = rsync'
      end

      def update
        cmd = 'emerge --update --deep --newuse @world'
        ChrootOutput.new(cmd)
      end
    end
  end
end
