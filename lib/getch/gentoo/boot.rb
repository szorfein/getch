module Getch
  module Gentoo
    class Boot
      def initialize(opts)
        @disk = opts.disk
        @user = opts.username
      end

      def start
        gen_fstab
      end

      private

      def gen_fstab
        mount = Getch::Mount.new(@disk, @user)
        mount.gen_fstab
      end
    end
  end
end
