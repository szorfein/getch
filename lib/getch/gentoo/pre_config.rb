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
        github = check_ip 'github.com'
        codeload = check_ip 'codeload.github.com'
        echo_a "#{OPTIONS[:mountpoint]}/etc/hosts", "#{github} github.com"
        echo_a "#{OPTIONS[:mountpoint]}/etc/hosts", "#{codeload} codeload.github.com"
      end

      def check_ip(host)
        ip = `ping -c1 #{host}`.match(/\([0-9]*.[0-9]*.[0-9]*.[0-9]*\)/)
        ip[0].tr('()','')
      end
    end
  end
end
