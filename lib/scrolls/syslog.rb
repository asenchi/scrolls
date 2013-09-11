require 'syslog'

module Scrolls
  class SyslogLogger
    def initialize(ident = 'scrolls')
      @syslog = Syslog.open(ident)
    end

    def puts(data)
      @syslog.log(Syslog::LOG_INFO, data)
    end
  end
end
