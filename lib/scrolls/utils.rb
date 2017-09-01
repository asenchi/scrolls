module Scrolls

  # Helpful map of syslog facilities
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

  # Helpful map of syslog log levels
  LOG_LEVEL_MAP = {
    "emerg"     => 0, # Syslog::LOG_EMERG
    "emergency" => 0, # Syslog::LOG_EMERG
    "alert"     => 1, # Syslog::LOG_ALERT
    "crit"      => 2, # Syslog::LOG_CRIT
    "critical"  => 2, # Syslog::LOG_CRIT
    "error"     => 3, # Syslog::LOG_ERR
    "warn"      => 4, # Syslog::LOG_WARNING
    "warning"   => 4, # Syslog::LOG_WARNING
    "notice"    => 5, # Syslog::LOG_NOTICE
    "info"      => 6, # Syslog::LOG_INFO
    "debug"     => 7  # Syslog::LOG_DEBUG
  }

  ESCAPE_CHAR = {
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
    "'" => "&#x27;",
    '"' => "&quot;",
    "/" => "&#x2F;"
  }

  ESCAPE_CHAR_PATTERN = Regexp.union(*ESCAPE_CHAR.keys)

  module Utils

    def self.escape_chars(d)
      if d.is_a?(String) and d =~ ESCAPE_CHAR_PATTERN
        esc = d.to_s.gsub(ESCAPE_CHAR_PATTERN) {|c| ESCAPE_CHAR[c] }
      else
        esc = d
      end
    end

  end
end
