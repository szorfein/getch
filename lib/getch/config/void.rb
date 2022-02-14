# frozen_string_literal: true

module Getch
  module Config
    class Void
      def shell
        command 'chsh -s /bin/bash'
      end
    end
  end
end
