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
        add_musl_repo if OPTIONS[:musl]
        update
      end

      private

      def sync
        gentoo_conf = "#{OPTIONS[:mountpoint]}/etc/portage/repos.conf/gentoo.conf"
        @log.info "Synchronize index, please waiting...\n"
        ChrootOutput.new('emaint sync --auto')
        sed gentoo_conf, /^sync-type/, 'sync-type = rsync'
      end

      def add_musl_repo
        Install.new('dev-vcs/git')

        file = "#{OPTIONS[:mountpoint]}/etc/portage/repos.conf/musl.conf"
        content = <<~CONF
        [musl]
        location = /var/db/repos/musl
        sync-type = git
        sync-uri = https://github.com/gentoo/musl.git
        auto-sync = Yes
        CONF
        File.write file, "#{content}\n"

        ChrootOutput.new('emaint sync -r musl')
      end

      def update
        cmd = 'emerge --update --deep --newuse @world'
        ChrootOutput.new(cmd)
      end
    end
  end
end
