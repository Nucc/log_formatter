require 'terminfo'
#require 'awesome_print'


# while !STDIN.eof? do
#   x = STDIN.readline
#   m = x.match(/.+({.+}).+/)
#   if m && m[1]
#     ap eval(m[1]) rescue puts x
#   else
#     puts x
#   end
# end

colors = ["31", "32", "33"]

$semaphore = Mutex.new

def colorize(color_code, text)
  "\e[#{color_code}m#{text}\e[0m"
end

def output(path, color, message)
  prefix = "#{colorize(color, '%-15.15s' % path)}" + colorize(color, "| ")
  height, width = TermInfo.screen_size

  $semaphore.synchronize do
    message.split("\n").each do |m|
      m.chars.each_slice(width-17) do |chunk|
        print prefix
        puts chunk.join
        STDOUT.flush
      end
    end
  end
end

def filters(text)
  if text =~ /Started|Completed 200/
    return colorize("36", text)
  elsif text =~ /Completed (4|5)/
    return colorize("31", text)
  elsif text =~ /Processing by (.+)? as (.+)?/
    m = text.match /Processing by (.+)? as (.+)?/
    text = "Processing by #{colorize(36, m[1])} as #{m[2]}"
  end

  text
end


threads = []

ARGV.each do |f|
  threads << Thread.new do
    path, name = f.split("|")
    color = colors.shift
    file = File.open(path, "r")
    file.seek(0, IO::SEEK_END)
    while true do
      select([file])
      line = file.gets
      if line
        output(name, color, filters(line))
      end
    end
  end
end


threads.map(&:join)
