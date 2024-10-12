# frozen_string_literal: true

require 'nito'

module Getch
  module Gentoo
    # update system gentoo
    class Update
      include NiTo

      def initialize
        @log = Log.new
        @dest = "#{OPTIONS[:mountpoint]}/etc/portage"
        x
      end

      protected

      def x
        gpg
        sync
        add_musl_repo if OPTIONS[:musl]
        update
      end

      private

      # https://wiki.gentoo.org/wiki/Gentoo_Binary_Host_Quickstart#Package_signature_verification
      # Fix permissions error on gnupg directory
      def gpg
        return unless OPTIONS[:binary]

        mv "#{@dest}/gnupg" "#{@dest}/gnupg.bak"
        ChrootOutput.new('getuto')
      end

      def sync
        gentoo_conf = "#{@dest}/repos.conf/gentoo.conf"
        @log.info "Synchronize index, please waiting...\n"
        ChrootOutput.new('emaint sync --auto')
        sed gentoo_conf, /^sync-type/, 'sync-type = rsync'
      end

      def add_musl_repo
        Install.new('dev-vcs/git')
        file = "#{@dest}/repos.conf/musl.conf"
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
