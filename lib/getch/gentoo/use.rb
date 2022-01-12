# frozen_string_literal: true

module Getch
  module Gentoo
    class Use
      def initialize(pkg = nil)
        @use_dir = "#{MOUNTPOINT}/etc/portage/package.use"
        @pkg = pkg
        @file = @pkg ? @pkg.match(/[\w]+$/) : nil
        @make = "#{MOUNTPOINT}/etc/portage/make.conf"
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
        File.write("#{@use_dir}/#{@file}", content, mode: 'w')
      end

      def write_global
        list = []
        @flags.each { |f| list << f unless Helpers.grep?(@make, /#{f}/) }
        use = list.join(' ')
        line = "USE=\"${USE} #{use}\"\n"
        File.write(@make, line, mode: 'a')
      end
    end
  end
end
