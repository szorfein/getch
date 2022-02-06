# frozen_string_literal: true

require 'logger'

module Getch
  class Log

    WHITE   = "\033[37m"
    CYAN    = "\033[36m"
    MAGENTA = "\033[35m"
    BLUE    = "\033[34m"
    YELLOW  = "\033[33m"
    GREEN   = "\033[32m"
    RED     = "\033[31m"
    BLACK   = "\033[30m"
    BOLD    = "\033[1m"
    CLEAR   = "\033[0m"

    def initialize(verbose = false)
      @log_file = '/tmp/log_install.txt'
      @verbose = verbose
      init
    end

    # TODO remove length
    def info(msg)
      tab = msg.match("\n") ? '' : add_tab(msg)
      l = msg.length
      @info.info "#{GREEN}#{BOLD} >>> #{CLEAR}#{l} #{WHITE}#{msg}#{CLEAR}" + tab
      @save.info(msg)
    end

    def result(msg)
      case msg
      when 'Ok'
        @result.info "#{GREEN}[ #{WHITE}#{msg}#{GREEN} ]#{CLEAR}\n"
      else
        @result.info "#{RED}[ #{WHITE}#{msg}#{RED} ]#{CLEAR}\n"
      end
    end

    def error(msg)
      @error.error "#{BOLD} > #{CLEAR}#{WHITE}#{msg}#{CLEAR}"
      @save.error(msg)
    end

    def debug(msg)
      @debug.debug "#{BOLD} > #{CLEAR}#{WHITE}#{msg}#{CLEAR}"
      @save.debug(msg)
    end

    def fatal(msg)
      @fatal.fatal "#{BOLD} > #{CLEAR}#{WHITE}#{msg}#{CLEAR}\n"
      @save.fatal(msg)
      exit 1
    end

    protected

    def init_log
      @info = Logger.new $stdout
      @info.level = @verbose ? Logger::DEBUG : Logger::INFO
      @info.formatter = proc { |severity, _, _, msg|
        "#{BOLD}#{severity[0]}#{CLEAR}#{msg}"
      }
    end

    def init_res
      @result = Logger.new $stdout, level: 'INFO'
      @result.formatter = proc do | _, _, _, msg | msg end
    end

    def init_debug
      @debug = Logger.new $stdout
      @debug.formatter = proc do | severity, _, _, msg |
        "\n#{BLUE}#{BOLD}#{severity[0]}#{CLEAR} [#{Process.pid}]#{CLEAR}#{msg}"
      end
    end

    def init_error
      @error = Logger.new $stdout
      @error.formatter = proc do | severity, _, _, msg |
        "#{RED}#{BOLD}#{severity[0]}#{CLEAR}#{msg}\t"
      end
    end

    def init_fatal
      @fatal = Logger.new $stdout
      @fatal.formatter = proc do | severity, _, _, msg |
        "\n#{YELLOW}#{BOLD}#{severity[0]}#{CLEAR}#{msg}"
      end
    end

    def init_save
      File.exist? @log_file || puts("Creating log at #{@log_file}")
      @save = Logger.new(@log_file, 1)
      @save.level = Logger::DEBUG
      @save.formatter = proc { |severity, datetime, _, msg|
        "#{severity}, #{datetime}, #{msg}\n"
      }
    end

    private

    def init
      init_log
      init_res
      init_error
      init_debug
      init_fatal
      init_save
    end

    def add_tab(text)
      case text.length
      when 39..46 then "\t\t"
      when 31..38 then "\t\t\t"
      when 22..30 then "\t\t\t\t"
      when 16..21 then "\t\t\t\t\t"
      else "\t"
      end
    end
  end
end
