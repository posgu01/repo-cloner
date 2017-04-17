require 'colorize'

module Puts
    def Puts.error(msg)
        puts msg.red
    end

    def Puts.warn(msg)
        puts msg.yellow
    end

    def Puts.info(msg)
        puts msg.green
    end

    def Puts.debug(msg)
        puts msg.blue
    end
end

module Print
    def Print.error(msg)
        print msg.red
    end

    def Print.warn(msg)
        print msg.yellow
    end

    def Print.info(msg)
        print msg.green
    end

    def Print.debug(msg)
        print msg.blue
    end
end
