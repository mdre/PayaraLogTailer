#!/usr/bin/ruby

require 'file-tail'
require 'optparse'
require 'ostruct'

#                   1                         2          3     4 5                    6                                                          7                                      8                             9                                                  
# ll = "[2019-08-02T08:52:51.268-0300] [Payara 5.192] [GRAVE] [] [] [tid: _ThreadID=56 _ThreadName=http-thread-pool::http-listener-1(2)] [levelValue: 1000] [http-thread-pool::http-listener-1(2)] ERROR com.vaadin.flow.server.DefaultErrorHandler -"
#       [2019-08-03T15:34:10.422-0300] [Payara 5.192] [INFORMACIÓN] [] [org.jvnet.hk2.osgiadapter] [tid: _ThreadID=32 _ThreadName=FelixStartLevel] [levelValue: 800] Skipping registration of inhabitant for service reference [org.osgi.service.metatype.MetaTypeProvider] as the service object could not be obtained.

###########################################
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
# Foreground
BLACK = 30
RED = 31
GREEN = 32
YELLOW = 33
BLUE = 34
MAGENTA = 35
CYAN = 36
LIGHTGRAY = 37
DARKGRAY = 90
LIGHTRED = 91
LIGHTGREEN = 92
LIGHTYELLOW = 93
LIGHTBLUE = 94
LIGHTMAGENTA = 95
LIGHTCYAN = 96
WHITE = 97

DEFAULT = 39
BACKDEF = 49
#Backgroud = Foreground + 10

def colorize(text, color_code, bold)
    "\e[1;#{bold};#{color_code}m#{text}\e[0m"
end
###########################################

def levelColor(level) 
    case level
    when "GRAVE"
        RED
    when "ADVERTENCIA"
        LIGHTRED
    when "DETALLADO"
        YELLOW
    when "MUY DETALLADO"
        LIGHTYELLOW
    else
        WHITE
    end
end
###########################################
def packageHightLight(text, pkgs)
    pkgs.each do |pkg|
        if text.start_with? pkg
            return colorize(text,LIGHTBLUE,BACKDEF)
        end
    end
end
###########################################
options =  OpenStruct.new
options.pkgs = []

OptionParser.new do |opts|
    opts.banner = "Usave: plv <path-to-file> -p <packages, ...>"
    opts.on("-p","--package x,y,z",Array,"hightlight package list") do |pkgs|
        options.pkgs = pkgs
    end
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

p options
p ARGV
p ARGV[0]


# https://rubular.com/
LOG_FORMAT = %r{
    \[(?<timestamp>[^\]]*)\]
    \s\[(?<organizationID>[^\]]*)\] 
    \s\[(?<Level>[^\]]*)\] 
    \s\[(?<MessageID>[^\]]*)\]
    \s\[(?<LoggerName>[^\]]*)\] 
    \s\[(?<ThreadID>[^\]]*)\] 
    \s\[(?<UserID>[^\]]*)\] 
    (\s(?<ECID>\[[^\]]*\]))? 
    (\s\[(?<Method>[^\]]*)\])? 
    \s(?<Message>.*)
}x

LOG_EXCEPTION = %r{
    \w*\s(?<class>(\w*)(\.\w*)*)
    \(
        (?<filename>[^:]*)
        \:
        (?<linenum>\d*)
    \)
}
# pLine = []
# pLine = ll.match(LOG_FORMAT)
# puts 
#return



filename = ARGV[0]

File.open(filename) do |log|
    log.extend(File::Tail)
    log.interval = 1 # 10
    log.backward(10)
    log.tail { |line| 
            matchLine = line.match(LOG_FORMAT)
            if (matchLine!=nil)    
                
                sTimestamp = matchLine[:timestamp]
                sLevel = colorize(matchLine[:Level],levelColor(matchLine[:Level]),BACKDEF)
                sLogger = packageHightLight(matchLine[:LoggerName],options.pkgs)
                sMethod = matchLine[:Method]
                sMessage = matchLine[:Message]
                
                puts "[#{sTimestamp}] [#{sLevel}] [#{sLogger}] [#{sMethod}] #{sMessage}"
                    
            else 
                matchLine = line.match(LOG_EXCEPTION)

                if (matchLine != nil)
                    sClass = packageHightLight(matchLine[:class],options.pkgs) 
                    sFile = matchLine[:filename]
                    sLine = matchLine[:linenum]

                    line.sub(matchLine[:class],sClass)

                    puts line
                else

                    puts line
                end
            end
            }
end