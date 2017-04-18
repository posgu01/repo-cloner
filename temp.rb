require 'colorize'

String.colors.each do |color|
    puts "This text is colored in #{color}".colorize(color)
end
