#!mruby
# coding: cp932

=begin

rubish classes 4 GR-CITRUS/mruby

#GR-CITRUSのピンを扱う基本Class
class Pin
 #initialize(pin,mode)
 #on!
 #off!
 #on?
 #off?
 #read
 #write(value)

# プッシュボタン類用
class Button
 #clicked?


# (単色)LED類
class Led

=end



OUTPUT       = 0x01
INPUT        = 0x00
INPUT_PULLUP = 0x02

class Pin

  HIGH = 1
  LOW  = 0
  ON   = 1
  OFF  = 0

  @sym_name_to_num = {
    'INPUT'        => INPUT,
    'INPUT_PULLUP' => INPUT_PULLUP,
    'OUTNPUT'      => OUTPUT,
    'HIGH'         => 1,
    'ON'           => 1,
    'LOW'          => 0,
    'OFF'          => 0
  }#eval;_;  
  
  attr_reader :pin
  attr_reader :status
  
  def initialize(pin, mode)
    fail 'pin mode required. INPUT or OUTPUT?' unless mode
    if pin.class == Symbol
      @pin = pin.to_s.split("_").last.to_i # :pin_3 => 3
    end

    if mode.class == Symbol
      mode = sym_name_to_num[mode.to_s.upcase] # :input => INPUT
    end

    
    @pin = pin
    
    pinMode(@pin, mode)
    @status = :off #起動時はOFF
    #if mode == INPUT
    #end
  end

  #
  # ピンをHIGH/ONにする
  #
  def on!
    digitalWrite(@pin, HIGH)
    @status = :on
  end
  alias :on! :high!
  
  #
  # ピンをLOW/OFFにする
  #
  def off!
    digitalWrite(@pin, LOW)
    @status = :off
  end
  alias :off! :low!

  #
  # ピンが ON/HIGH であれば true
  #
  def on?
    digitalRead(@pin) == ON
    #@status == OFF
  end

  #
  # ピンが OFF/LOW であれば true
  #
  def off?
    digitalRead(@pin) == OFF
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

  def set_refernce(mode)
    # 0 : def5.0v arduino, 1:INTERNAL 1.1, 2:EXTERNAL:AVREFpin, 3:RAW 12bit 3.3V
    analogRefernce(mode)
  end

  def tone(freq, duration=0)
    tone(@pin,freq,duration)
  end

  def no_tone
    noTone(@pin)
  end
  
end
include Pin


class Switch < Pin
end

class Button < Pin
  def initialize(pin, mode=INPUT_PULLUP)
    super
    @interval_time = 100 #押す間隔
  end

  def click? #短く押されたことを検知
    
  end
  alias :click? :pushed?
  
  def double_click?
    
  end

  def run #loop化?
    #Threadで監視したら何クリックかとれるよね
  end
  
end

class Led < Pin
  def initialize(pin, mode=OUTPUT)
    super
  end

  def blink(interval_time=1000) # 偶数秒だけ点灯Threadが必要か? 
    #Fiber?
  end

  def write(value)
    analogWrite(@pin, value)
  end
end


class PhotoCell < Pin
  def initialize(pin, mode=INPUT)
    super
  end

  def value
    analogRead(@pin)
  end
end

class RGB_Led
  def initialize(r_pin,g_pin,b_pin)
    @r = Led.new(r_pin)
    @g = Led.new(r_pin)
    @b = Led.new(r_pin)
  end
end


class Volume < Pin
  
end

class SonicSensor_HCSR04
  def initialize(trig_pin, echo_pin)
    @trig = Pin.new(trig_pin, INPUT)
    @echo = Pin.new(echo_pin, OUTPUT)
  end

  
end

class TA7291P #MotorDriver
  attr_reader :status
  
  def initialize(pin_a,pin_b)
    if pin_a.class == Symbol
      @pin_a = pin_a.to_s.split("_").last.to_i # :pin_3 => 3
    end
    if pin_b.class == Symbol
      @pin_b = pin_b.to_s.split("_").last.to_i # :pin_3 => 3
    end
    
    @pin_a = pin_a
    @pin_b = pin_b

    @freq   = 0
    @status = :stop
    
    pinMode(@pin_a, OUTPUT)
    pinMode(@pin_b, OUTPUT)
  end

  def rotate!
    @status = :rotate
    if @mode == :pwm
      analogWrite(@pin_a, @freq)
    else
      digitalWrite(@pin_a, HIGH)
    end
    digitalWrite(@pin_b, LOW)
  end

  def reverse!
    @status = :reverse
    digitalWrite(@pin_a, LOW)
    if @mode == :pwm
      analogWrite(@pin_b, @freq)      
    else
      digitalWrite(@pin_b, HIGH)
    end
  end

  def stop!
    @status = :stop
    digitalWrite(@pin_a, LOW)
    digitalWrite(@pin_b, LOW)
  end

  def break!#?
    @status = :breaking
    digitalWrite(@pin_a, HIGH)
    digitalWrite(@pin_b, HIGH)    
  end
  
  # analog??
  # pwm??
  def set_speed(freq)
    @freq = freq
  end

  def set_mode(mode)
    case mode
    when :pwm
      @mode = :pwm
    else #=> normal
      @mode = :normal
    end
  end

  #状態に応じて出力をそのままに
  def keep_monitor
    # Fiber?
    
    case @status
    when :rotate
      self.rorate!
    when :reverse
      self.reverse!
    when :stop
      self.stop!
    end
  end
end


