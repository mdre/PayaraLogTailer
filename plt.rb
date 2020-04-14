#!/usr/bin/ruby

require 'file-tail'
require 'optparse'
require 'ostruct'
require 'io/console'


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
    hlText = text
    pkgs.each do |pkg|
        #puts "text: #{text} pkg: #{pkg}"
        if text.start_with? pkg
            hlText = colorize(text,LIGHTBLUE,BACKDEF)
            break 
        end
    end
    hlText
end
###########################################
def keyCapture() 
    loop do
        ch = $stdin.getch
        case ch 
        when 'q'    then exit
        when "\c?"  then puts 'backspace'
        when "\t"  then puts 'tab'
        else 
            puts ch
        end
    end
end
###########################################

options =  OpenStruct.new
options.pkgs = []
options.removeBlanks = true
options.showFullTime = false
options.showFullLogLevelName = false

OptionParser.new do |opts|
    opts.banner = "Usave: plt <path-to-file> -p <packages, ...>"
    opts.on("-p","--package x,y,z",Array,"hightlight package list") do |pkgs|
        options.pkgs = pkgs
    end
    opts.on("-s","--show-blank","show blank lines") do |rb|
        options.removeBlanks = false
    end
    opts.on("-t","--fulltime","show the full time format") do |t|
        options.showFullTime = true
    end
    opts.on("-l","--longLevelFormat","show the full logger level name") do |t|
        options.showFullLogLevelName = true
    end
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

#p options
#p ARGV
#p ARGV[0]

# https://rubular.com/
LOG_FORMAT = %r{
    \[
        (?<date>[^T]*)\T
        (?<time>[^\.]*)
        (\.(?<millis>[^\]]*))?
    \]
    \s\[(?<organizationID>[^\]]*)\] 
    \s\[(?<Level>[^\]]*)\] 
    \s\[(?<MessageID>[^\]]*)\]
    \s\[(?<LoggerName>[^\]]*)\] 
    \s\[(?<ThreadID>[^\]]*)\] 
    \s\[(?<UserID>[^\]]*)\] 
    (\s(?<ECID>\[[^\]]*\]))? 
    (\s\[CLASSNAME\:(?<Classname>[^\]]*)\])?
    (\s\[METHODNAME\:(?<Method>[^\]]*)\])? 
    \s(
       \[{2}(?<Message>.*)\]\]
       |
       (?<Message>.*)
       )
}xm

LOG_EXCEPTION = %r{
    \w*\s(?<class>(\w*)(\.\w*)*)
    \(
        (?<filename>[^:]*)
        \:
        (?<linenum>\d*)
    \)
}

###########################################
#t1 = Thread.new{keyCapture()}

filename = ARGV[0]

File.open(filename) do |log|
    log.extend(File::Tail)
    log.interval = 1 # 10
    log.max_interval = 3
    log.backward(10)
    log.tail { |line| 
            fLine = ""
            # intentar matchear contra el formato de Log
            matchLine = line.match(LOG_FORMAT)
            if (matchLine!=nil)    
                
                sDate = matchLine[:date]
                sTime = matchLine[:time]
                sMillis = options.showFullTime ? "."+matchLine[:millis] : ""

                sLevel = colorize(options.showFullLogLevelName ? matchLine[:Level] : matchLine[:Level][0..3],levelColor(matchLine[:Level]),BACKDEF)
                sLogger = packageHightLight(matchLine[:LoggerName], options.pkgs)
                sMethod = matchLine[:Method]
                sMessage = matchLine[:Message].strip()
                 
                fLine = "[#{sDate} #{sTime}#{sMillis}] [#{sLevel}] [#{sLogger}] [#{sMethod}] #{sMessage}"
                    
            else 
                # si no mapea, intentar formatear la linea en busca de paquetes para el caso que sea una excepción
                matchLine = line.match(LOG_EXCEPTION)

                if (matchLine != nil)
                    sClass = packageHightLight(matchLine[:class],options.pkgs) 
                    sFile = matchLine[:filename]
                    sLine = matchLine[:linenum]

                    fLine = line.sub(matchLine[:class],sClass)

                else
                    fLine = line.strip()
                    
                end
            end
            
            if !((fLine.empty? || fLine == "\n") && options.removeBlanks)
                puts fLine
            end
            
        }
end
