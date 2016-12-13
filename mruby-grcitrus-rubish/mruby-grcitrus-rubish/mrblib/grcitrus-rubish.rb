# coding: cp932
##
# GR-CITRUS Rubish
#
=begin



=end


OUTPUT       = 0x01
INPUT        = 0x00
INPUT_PULLUP = 0x02
HIGH         = 1
LOW          = 0
ON           = 1
OFF          = 0


class Pin
  @sym_name_to_num = {
    'INPUT'        => INPUT,
    'INPUT_PULLUP' => INPUT_PULLUP,
    'OUTNPUT'      => OUTPUT,
    'HIGH'         => HIGH,
    'ON'           => HIGH,
    'LOW'          => LOW,
    'OFF'          => LOW
  }#eval;_;  
  
  attr_reader :pin
  attr_reader :status
  
  def initialize(pin, mode)
    fail 'pin mode required. INPUT or OUTPUT?' unless mode
    if pin.class == Symbol
      @pin = pin.to_s.split("_").last.to_i # :pin_3 => 3
    else
      @pin = pin
    end

    if mode.class == Symbol
      mode = sym_name_to_num[mode.to_s.upcase] # :input => INPUT
    end
    @mode = mode #INPUT_PULLUPしてるときってLOWがON?

    pinMode(@pin, @mode)
    @status = :off #起動時はOFF
    #if mode == INPUT
    #end
  end

  #
  # ピンをHIGH/ONにする
  #
  def on
    digitalWrite(@pin, HIGH)
    @status = :on
  end
  alias :high :on
  
  #
  # ピンをLOW/OFFにする
  #
  def off
    digitalWrite(@pin, LOW)
    @status = :off
  end
  alias :low :off

  #
  # ピンが ON/HIGH であれば true
  #
  def on?
    digitalRead(@pin) == LOW
    #@status == OFF
  end

  #
  # ピンが OFF/LOW であれば true
  #
  def off?
    digitalRead(@pin) == HIGH
    #@status == OFF
  end

  #
  # ピンのアナログ読み出し
  #
  def read
    analogRead(@pin)
  end

  #
  # ピンにアナログ書き込み
  #
  def write(value)
    @status = :on #?
    analogWrite(@pin, value)
  end

  def analog_reference=(mode)
    # 0 : def5.0v arduino, 1:INTERNAL 1.1, 2:EXTERNAL:AVREFpin, 3:RAW 12bit 3.3V
    analogReference(mode)
  end

  def tone(freq, duration=0)
    tone(@pin,freq,duration)
  end

  def no_tone
    noTone(@pin)
  end
  
end

#
# 入力用デバイス
#
class InputDevice < Pin
  def initialize(pin, mode=INPUT_PULLUP)
    super
  end
end
#アナログ用で別クラス必要?

#
# 出力用デバイス
#
class OutputDevice < Pin
  def initialize(pin, mode=OUTPUT)
    super
  end
end

#
# Button,LED(PhotoCoupler)ほか部品名で定義
#
Button = InputDevice
Switch = InputDevice
Led = OutputDevice
PhotoCoupler = OutputDevice

#
# LEDマトリックス(8x8しか想定してないです)
#
module LEDmatrix
  HT16K33_CMD_BLINK = 0x80
  HT16K33_CMD_BRIGHTNESS = 0xE0
  HT16K33_CMD_BLINK_DISPLAYON = 0x01
  HT16K33_BLINKOFF = 0
  HT16K33_BLINK1HZ = 1
  HT16K33_BLINK2HZ = 2
  HT16K33_BLINKHALFHZ = 3

  attr_accessor :buffer

  def init_display(opt={:wire=>1, :addr=>0x70})
    @addr = opt[:addr] || 0x70
    @wire = opt[:wire]

    @buffer = [
      '00000000',
      '00000000',
      '00000000',
      '00000000',
      '00000000',
      '00000000',
      '00000000',
      '00000000'
    ]
    @matrix = I2c.new(@wire)
    self.send_cmd(0x21)
    self.blink_rate = 0
    self.brightness = 10
  end

  def send_cmd(cmd)
    @matrix.begin(@addr)
    @matrix.lwrite(cmd)
    @matrix.end
  end

  public
  def brightness=(b)
   self.send_cmd( HT16K33_CMD_BRIGHTNESS|b )
  end

  def blink_rate=(rate)
    rate = 0 if rate > 3
    self.send_cmd( HT16K33_CMD_BLINK|HT16K33_CMD_BLINK_DISPLAYON|(rate << 1) )
  end
  
  def clear
    @ini_buffer = [
      '00000000',
      '00000000',
      '00000000',
      '00000000',
      '00000000',
      '00000000',
      '00000000',
      '00000000'
    ]
    @buffer = @ini_buffer
    @matrix.begin(@addr)
    @matrix.lwrite( 0x00 )
    8.times do
      @matrix.lwrite(0b00000000)
      @matrix.lwrite(0b00000000)
    end
    @matrix.end
  end
  
  def draw_pixel(x,y,col=1)
    @buffer[y][x] = color.to_s
    self.write_display
  end
  
  def shift(direction)
    case direction
    when :up # ^
      @buffer = [ @buffer[1],
                  @buffer[2],
                  @buffer[3],
                  @buffer[4],
                  @buffer[5],
                  @buffer[6],
                  @buffer[7],
                  @buffer.first ]
    when :down # v
      @buffer = [ @buffer[7],
                  @buffer[0],
                  @buffer[1],
                  @buffer[2],
                  @buffer[3],
                  @buffer[4],
                  @buffer[5],
                  @buffer[6] ]
    when :left # <
      @buffer = @buffer.map do |s|
        [s[1..-1],s[0]].join
      end
    when :right # >
      @buffer.map! do |s|
        [s[-1],s[0..-2]].join
      end
    end
    self.write_display
  end

  def slide_in_from(buf,direction=:down, delay_time=810, before_clear=true)
    self.clear if before_clear
    case direction
    when :down
      cnt = 0
      7.downto(0) do |r|
        @buffer[0..cnt] = buf[((cnt+1)*-1)..-1]
        cnt += 1
        self.write_display
        delay(delay_time)
        
      end
    end
  end

  def fade_in(buf,direction=:up, delay_time=810)
    
  end
  
  
  def write_display
  end
  alias :display :write_display


  #
  # パーツ単位
  #
  class BiColor_8x8
    include LEDmatrix
    def initialize(opt)
      init_display(opt)
    end
    
    def write_display
      # BUF : 0off 1red 2green 3orange
      @matrix.begin(@addr)
      @matrix.lwrite( 0x00 )

      @buffer.each do |pat|
        r_line = ""
        g_line = ""
        pat.each_char do |c|
          case c
          when "0"
            r_line += "0"
            g_line += "0"
          when "1"
            r_line += "1"
            g_line += "0"
          when "2"
            r_line += "0"
            g_line += "1"
          when "3"
            r_line += "1"
            g_line += "1"
          end
        end

        @matrix.lwrite( r_line.reverse.to_i(2) )
        @matrix.lwrite( g_line.reverse.to_i(2) )
      end
      @matrix.end()
    end
  end

  class MonoColor_8x8
    include LEDmatrix
    def initialize(opt)
      init_display(opt)
    end
    def write_display
      @matrix.begin(@addr)
      @matrix.lwrite( 0x00 )

      @buffer.each do |pat|
        dbit = "#{pat[0]}#{pat[1..-1].reverse}".to_i(2)
        @matrix.lwrite( dbit )
        @matrix.lwrite( 0x00 )
      end
      @matrix.end()
    end
  end
  
end


#
# モータドライバ
#
module MotorDriver
  attr_reader :status
  attr_reader :mode
  
  def define_pin(pin_a, pin_b)
    if pin_a.class == Symbol
      @pin_a = pin_a.to_s.split("_").last.to_i # :pin_3 => 3
    end
    if pin_b.class == Symbol
      @pin_b = pin_b.to_s.split("_").last.to_i # :pin_3 => 3
    end
    @speed  = nil
    @status = :stop
    @mode   = :normal
  end

  private
  def write(p1, p2)
    if @mode == :pwm #未実装
      
    end
    digitalWrite(@pin_a, p1)
    digitalWrite(@pin_b, p2)
  end

  public
  def rotate(p1,p2)
    @status = :rotate
    write(p1,p2)
  end

  def reverse(p1,p2)
    @status = :reverse
    write(p1,p2)
  end

  def stop(p1,p2)
    @status = :stop
    write(p1,p2)
  end

  def breaking(p1,p2)
    @status = :breaking
    write(p1,p2)
  end

  def speed=(speed)
    #なにか制御いれる？
    @speed = speed
  end

  def mode=(mode)
    case mode
    when :pwm
      @mode = :pwm
    else #=> normal
      @mode = :normal
    end
  end
  

  class TA7291P
    include MotorDriver
    def initialize(*pins)
      define_pin(*pins)
    end

    def rotate(p1=HIGH, p2=LOW); super; end
    def reverse(p1=LOW, p2=HIGH); super; end
    def stop(p1=LOW, p2=LOW); super; end
    def breaking(p1=HIGH, p2=HIGH); super; end
  end

end

#
# CharactorLCD 
#


# 
# I2C温度センサ
#
class BME
  def initialize
    puts "DUMMY"
  end
end


module Citrus
  class Appication
    def initialize
    end

    def run
    end
  end
end

