module Getch
  module Gentoo
    class Use
      def initialize(pkg)
        @use_dir = "#{MOUNTPOINT}/etc/portage/package.use"
        @pkg = pkg
        @file = @pkg.match(/[\w]+$/)
      end

      def add(*flags)
        @flags = flags.join(' ')
        write
      end

      private
      def write
        content = "#{@pkg} #{@flags}"
        File.write("#{@use_dir}/#{@file}", content, mode: 'w')
      end
    end
  end
end
