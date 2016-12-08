# coding: utf-8

class MyApplication
  def initialize
    @btns           = {}
    @motors         = {}

    @btns[:left]    = Button.new(:pin_3)
    @btns[:right]   = Button.new(:pin_2)
    @motors[:left]  = TA7291P.new(:pin_5, :pin_6)
    @motors[:right] = TA7291P.new(:pin_7, :pin_8)
    @led_red_1      = Led.new(:pin_4)
    #@sensor         = SonicSensor_HCSR04.new(:pin_10, :pin_11)
  end

  def run
    loop do
      [:left, :right].each do |direction|
        if @btns[direction].clicked?
          @led_red1.on!
          @motors[direction].rotate!
        else
          @motors[direction].stop!
        end
      end

      #状態に応じて実行する イベントマシンとかつかえんの?
      @motor_f.keep_monitor
    end
  end
  
end

MyApplication.new.run
