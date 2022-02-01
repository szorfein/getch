# frozen_string_literal: true

module Getch
  module Config
    class Account
      def initialize
        @user = OPTIONS[:username] ||= nil
        @log = Log.new
      end

      def root
        @log.info "Add a password for root.\n"
        ChrootOutput.new('passwd')
      end

      def new_user
        return unless @user

        create_user
        @log.info "Add a password for #{@user}.\n"
        ChrootOutput.new("passwd #{@user}")
        fix_perm
      end

      private

      def create_user
        @log.info "Creating a new user #{@user}..."
        Getch::Chroot.new("useradd -m -G users,wheel,audio,video #{@user}")
        @log.result 'Ok'
      end

      def fix_perm
        Getch::Chroot.new("chown -R #{@user}:#{@user} /home/#{@user}")
        Getch::Chroot.new("chmod 700 -R /home/#{@user}")
      end
    end
  end
end
