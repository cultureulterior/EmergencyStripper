#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'serialport'
require 'net/http'
require 'json'
require 'yaml'
require 'color'
require 'ostruct'
require 'timeout'

Config = OpenStruct.new(YAML.load(IO.read("config.yaml")))

Green = Color::RGB.by_hex("00FF00").to_hsl
Red = Color::RGB.by_hex("FF0000").to_hsl
def connect()
  $sp = SerialPort.new(Config.device, 115200, 8, 1, SerialPort::NONE)
  puts "Connecting to serial port"
end
connect()
uri = URI(Config.source)
conn = Net::HTTP.new(uri.host,uri.port)
conn.cert = OpenSSL::X509::Certificate.new(IO.read(Config.cert))
conn.key = OpenSSL::PKey::RSA.new(IO.read(Config.key))
conn.use_ssl = true
conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
conn.read_timeout = 5
conn.open_timeout = 5

def unexcept(*ex)
    begin 
      yield 
    rescue *ex => res
      $stderr.puts("Unexcepting #{res}")
      nil
    end
end

#conn.set_debug_output $stderr
    
puts "entering system"
while true
  if (
      (url = Config.source) &&
      (file = unexcept(Timeout::Error,SystemCallError,SocketError){conn.get(uri.path)}) &&
      (json = file.body) &&
      (data = unexcept(JSON::ParserError){JSON.parse(json)}) &&
      (dists = data["Dists"]) &&
      (error_rates = dists.select{|k,v| k[/integration.+error_rate/]}).length > 0
  )
    numeric_error_rates = error_rates
    			.map{|k,v| [k,v["Sum_x"]/v["N"]]}
			.to_h
			.reject{|k,v| k[/staging/]}
    error_rate = numeric_error_rates.values.max
    #error_rate = 0.5
    color = Green.mix_with(Red,error_rate).to_rgb.hex
    characters = [color].pack('H*').gsub(" ","!")
    checksum = characters.each_byte.reduce{|o,n| o^n}
    puts "Recieving data for #{data['Timestamp']}, error rates #{numeric_error_rates}"
    puts "Sending data color #{characters.unpack('H*').first}, encoding #{characters.encoding}, checksum #{checksum}"
    4.times do
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
      Kernel.sleep 1.0
    end
  else
    puts "ERROR IN HTTP RECIEVED DATA '#{file}' \n\n '#{json}' \n\n '#{data}' \n\n '#{error_rates}'"
    #p file,json
    #puts JSON.pretty_generate(data)	   
    #p data["integration.message.production.error_rate"],error_rate_dist,error_rate_object
  end
  Kernel.sleep 1.0
end
