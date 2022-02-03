# frozen_string_literal: true

module Getch
  module Gentoo
    class PreConfig
      def initialize
        x
      end

      private

      def x
        Getch::Config::Portage.new
        Getch::Config::Locale.new
        Getch::Config::PreNetwork.new
        add_musl_repo if OPTIONS[:musl]
      end

      def add_musl_repo
        file = "#{OPTIONS[:mountpoint]}/etc/portage/repos.conf/musl.conf"
        content = <<~CONF
        [musl]
        location = /var/db/repos/musl
        sync-type = git
        sync-uri = https://github.com/gentoo/musl.git
        auto-sync = Yes
        CONF
        File.write file, "#{content}\n"
        Install.new('dev-vcs/git')
      end
    end
  end
end
