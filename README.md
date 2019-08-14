# PayaraLogTailer
A Payara log tailer formatter 

Usage: `plt <path-to-file> -p <packages, ...>`

Parameters:
```
    -p, --package x,y,z              hightlight package list
    -s, --show-blank                 show blank lines
    -t, --fulltime                   show the full time format
    -l, --longLevelFormat            show the full logger level name
    -h, --help                       Show this message
```

As a default, plt remove the blank lines that Payara show between every log, and show only the timestampt without the millis.

## Install 
- clone the project
- install `file-tail` gem
- set execution permisions
- add a shotcut

ej:
```
cd /opt
sudo gem install file-tail
>>>>>>> e4bf77f62a8a63dbffd87d7cf8726c90a888307c
git clone git@github.com:mdre/PayaraLogTailer.git

chmod 755 /opt/PayaraLogTailer/plt.rb 

sudo ln -s /opt/PayaraLogTailer/plt.rb /usr/bin/plt
```

## How to use:
```
plt -p ar.gob.santafe,net.odbogm /opt/payara/glassfish/domains/domain1/logs/server.log
```
