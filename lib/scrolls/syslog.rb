require 'syslog/logger'

module Scrolls
  class SyslogLogger < ::Syslog::Logger
    def puts(data)
      info(data)
    end
  end
end
