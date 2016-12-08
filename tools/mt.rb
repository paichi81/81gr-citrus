#!/usr/local/bin/ruby
# coding: utf-8
=begin

共用ライブラリをはさみこんでからmrbcしつつ
make and transfer .mrb file


cat grcitrus_rubish.rb hoge.rb > newHoge.rb
mrbc newHoge.rb
wc -w < newHoge.mrb
したあと、SerialPort経由でファイルを送り込み
ターミナルモードに移行

=end
require 'serialport'

port = "/dev/tty.usbmodem1_1"
bps  = 9600
send_script_name = "main"
sending_timeout = 10 #sec

script_file = ARGV.shift
#mrb_file    = script_file.split(".").first + ".mrb"
mrb_file = "main.mrb"
shared_library = "~/devel/gr-citrus/81gr-citrus/grcitrus_rubish.rb"

`cat #{shared_library} #{script_file} > main.rb`


cmd = "mrbc -g main.rb"
#cmd = "mrbc -g #{script_file}  -o#{mrb_file}"
puts cmd
puts `#{cmd}`
size = open("|wc -c <#{mrb_file}").readlines.join.chomp.strip.to_i


sp = SerialPort.new(port,bps,8,1,SerialPort::NONE)

$wait4upload = true
$buf = ""

Thread.new{ #Waiting xx xx を受信するまではアップロードまちで、受信内容を表示
  loop do
    line = sp.getc

    $wait4upload = false if $buf =~ /Wait/

    $buf += line
    $buf == "" if line == "¥n"
    print line
  end
}

#
#sp.print "L¥r¥n"
sp.write "¥r¥n"
sleep 4

#
# Transfer  .mrb file (Xコマンド送信)
#
retry_count = 0
begin
  first_send_time = Time.now
  cmd = "¥r¥nX #{send_script_name} #{size}"
  STDERR.puts cmd
  sp.write "X #{send_script_name} #{size}"
  sp.write "¥r¥n"

  #雑な待ち受け
  STDERR.puts "Wait for upload"
  while $wait4upload
    raise "Time Out "  if Time.now-first_send_time >= sending_timeout
  end
  STDERR.puts
rescue
  if  retry_count <= 2
    retry_count += 1
    retry
  else
    STDERR.puts "timeout error;_;"
    exit
  end
end

STDERR.puts " ** sending #{mrb_file} : #{size} bytes ** "
sleep 5
open(mrb_file,"rb") do |io|
  io.each_byte do |b|
    sp.putc b
  end
end
sp.write "¥r¥n"

#
# そのままターミナルモードに移行(^Cでとまる)
#
loop do
  line = gets
  sp.write line
end
sp.close

