#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'serialport'
require 'open-uri'
require 'json'
require 'color'

Green = Color::RGB.by_hex("00FF00").to_hsl
Red = Color::RGB.by_hex("FF0000").to_hsl
def connect()
  $sp = SerialPort.new(ARGV[1], 115200, 8, 1, SerialPort::NONE)
  puts "Connecting to serial port"
end
connect()
while true
  if (
      (url = ARGV[0]) &&
      (file = open(url,{:read_timeout=>10})) &&
      (json = file.read) &&
      (data = JSON.parse(json)) &&
      (error_rate_dist = data["integration.message.production.error_rate"]) &&
      (error_rate_dist_first = error_rate_dist.first) &&
      (error_rate_object = error_rate_dist_first["Dist"])
  )
    error_rate = error_rate_object["Sum_x"]/error_rate_object["N"]
    #error_rate = 0.5
    color = Green.mix_with(Red,error_rate).to_rgb.hex
    characters = [color].pack('H*').gsub(" ","!")
    checksum = characters.each_byte.reduce{|o,n| o^n}
    puts "Recieving data for #{error_rate_dist_first['Timestamp']}, error rate #{error_rate}"
    puts "Sending data color #{characters.unpack('H*').first}, encoding #{characters.encoding}, checksum #{checksum}"
    begin
      $sp.putc(32)
      $sp.print(characters)
      $sp.putc(checksum)
      puts "Arduino sez:"+$sp.read_nonblock(256)
    rescue IO::EAGAINWaitReadable => ex
      puts "Arduino no talky"
    rescue EOFError,SystemCallError => ex
      puts "End of file, trying to reconnect"
      begin
        $sp.close
        connect()
      rescue Exception => ex2
        $stderr.puts "Exception when trying to reconnect #{ex2}"
      end
    end
  else
    puts "ERROR IN HTTP RECIEVED DATA #{file} @@ #{json} @@ #{data} @@ #{error_rate_dist} @@ #{error_rate_object}"
  end
  Kernel.sleep 5
end
