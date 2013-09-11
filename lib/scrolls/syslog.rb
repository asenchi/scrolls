require 'syslog'

module Scrolls

  LOG_FACILITY = ENV['LOG_FACILITY'] || Syslog::LOG_USER
  LOG_FACILITY_MAP = {
    "auth"     => Syslog::LOG_AUTH,
    "authpriv" => Syslog::LOG_AUTHPRIV,
    "cron"     => Syslog::LOG_CRON,
    "daemon"   => Syslog::LOG_DAEMON,
    "ftp"      => Syslog::LOG_FTP,
    "kern"     => Syslog::LOG_KERN,
    "mail"     => Syslog::LOG_MAIL,
    "news"     => Syslog::LOG_NEWS,
    "syslog"   => Syslog::LOG_SYSLOG,
    "user"     => Syslog::LOG_USER,
    "uucp"     => Syslog::LOG_UUCP,
    "local0"   => Syslog::LOG_LOCAL0,
    "local1"   => Syslog::LOG_LOCAL1,
    "local2"   => Syslog::LOG_LOCAL2,
    "local3"   => Syslog::LOG_LOCAL3,
    "local4"   => Syslog::LOG_LOCAL4,
    "local5"   => Syslog::LOG_LOCAL5,
    "local6"   => Syslog::LOG_LOCAL6,
    "local7"   => Syslog::LOG_LOCAL7,
  }

  class SyslogLogger
    def initialize(ident = 'scrolls', facility = Syslog::LOG_USER)
      @syslog = Syslog.open(ident, Syslog::LOG_PID|Syslog::LOG_CONS, facility)
    end

    def puts(data)
      @syslog.log(Syslog::LOG_INFO, data)
    end

    def close
      @syslog.close
    end
  end
end
