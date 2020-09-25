require 'logger'

module Getch
  class Log
    def initialize
      init_log
      init_log_text
    end

    def info(msg)
      @logger.info(msg)
      @logger_text.info(msg)
    end

    def error(msg)
      @logger.error(msg)
      @logger_text.error(msg)
    end

    def debug(msg)
      @logger.debug(msg)
      @logger_text.debug(msg)
    end

    private

    def init_log
      @logger = Logger.new(STDOUT)
      @logger.level = DEFAULT_OPTIONS[:verbose] ? Logger::DEBUG : Logger::INFO
      @logger.formatter = proc { |severity, datetime, progname, msg|
        "#{severity}, #{msg}\n" 
      }
    end

    def init_log_text
      @logger_text = Logger.new("/tmp/log_install.txt", 1)
      @logger_text.level = Logger::DEBUG
      @logger_text.formatter = proc { |severity, datetime, progname, msg|
        "#{severity}, #{datetime}, #{msg}\n" 
      }
    end
  end
end
