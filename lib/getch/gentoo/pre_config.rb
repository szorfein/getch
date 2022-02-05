# frozen_string_literal: true

require 'nito'

module Getch
  module Gentoo
    class PreConfig
      include NiTo

      def initialize
        x
      end

      private

      def x
        Getch::Config::Portage.new
        Getch::Config::Locale.new
        Getch::Config::PreNetwork.new
        github
      end

      # Trouble to find host github
      def github
        git = `ping -c1 github.com`.match(/\([0-9]*.[0-9]*.[0-9]*.[0-9]*\)/)
        ip_only = git[0].tr('()','')
        echo_a "#{OPTIONS[:mountpoint]}/etc/hosts", "#{ip_only} github.com"
      end
    end
  end
end
