# frozen_string_literal: true

require 'nito'

module Getch
  module Gentoo
    # Utility to configure use flag on Gentoo
    class Use
      include NiTo

      def initialize(pkg = nil)
        @use_dir = "#{OPTIONS[:mountpoint]}/etc/portage/package.use"
        @pkg = pkg
        @file = @pkg ? @pkg.match(/[\w]+$/) : nil
        @make = "#{OPTIONS[:mountpoint]}/etc/portage/make.conf"
      end

      def add(*flags)
        @flags = flags.join(' ')
        write
      end

      def add_global(*flags)
        @flags = flags
        write_global
      end

      private

      def write
        content = "#{@pkg} #{@flags}\n"
        echo "#{@use_dir}/#{@file}", content
      end

      def write_global
        list = []
        @flags.each { |f| list << f unless grep?(@make, f) }
        use = list.join(' ')
        echo_a @make, "USE=\"${USE} #{use}\""
      end
    end
  end
end
