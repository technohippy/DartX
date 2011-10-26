require 'curses'
require 'io/nonblock'
require 'gorispace'

class Gorispace
  def dartspace(str)
    scan(str.gsub('.', 'A').gsub('|', 'B').gsub('@', 'C'))
    execute
  end
end

class Dart
  include Curses

  CENTER =6 
  CURSORS = %w(\\ - / -)
  DART = '<#>---=-'
  TARGET = '@'
  SHOTS = [
    [ 0,-1,-1,-1,-1,-1,-2,-2,-2,-2,-2,-2,-2,-3,-3,-3,-3,
     -3,-4,-4,-4,-4,-5,-5,-5,-6,-6,-6,-7,-7,-8,-8,-9], 
    [ 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-2,-2,-2,-2,-2,-3,-3,-3,-4,-4], 
    [ 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3,
      3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 1, 1, 1, 0, 0, 0], 
    [ 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-2,-2,-2,-2,-2,-3,-3,-3,-4,-4], 
  ]

  def initialize(filename)
    if filename
      @codes = File.read(filename).split("\n").map{|i| {
        '<#>---=-'  => 0,
        '<#>---=-|' => 1,
        '<#>---=-@' => 2,
      }[i]}
    end
    @loaded_code = []
  end

  def start(opt)
    @opt = opt

    Signal.trap(:INT) do 
      echo
      exec
      exit
    end

    begin
      noecho
      STDIN.nonblock = true
      init_screen
      loop do
        angle = next_code
        break if angle.nil?
        draw_flying angle
        @loaded_code << angle
      end
    ensure
      echo
      close_screen
    end
    exec
  end

  def list
    @loaded_code.map{|a| ['.', '|', '@', '|'][a]}.join
  end

  def draw_target
    ((-4..-1).to_a+(1..4).to_a).each do |l|
      setpos CENTER+l, 40
      addstr '|'
    end
    setpos CENTER, 40
    addstr TARGET
  end

  def draw_hand(angle)
    clear
    draw_target
    setpos CENTER, 2
    addstr CURSORS[angle]
    setpos 0, 0
    addstr list.size < 40 ? list : list[-40..-1]
    refresh
  end

  def draw_arrow(angle, c)
    clear
    draw_target
    setpos CENTER-SHOTS[angle][c], c
    addstr DART
    setpos 0, 0
    addstr list.size < 40 ? list : list[-40..-1]
    refresh
  end

  def next_code
    if @codes and not @codes.empty?
      @codes.shift
    else
      wait_input
    end
  end

  def wait(sec)
    #sleep sec if @opt[:wait]
    sleep 2 if @opt[:wait]
  end

  def wait_input
    stop = false
    angle = 0
    t = Thread.new do
      loop do
        break if stop
        angle = (angle + 1) % 4
        draw_hand angle
        wait 0.3
      end
    end

    while getch.nil?
      wait 0.1
    end
    stop = true
    t.join
    angle
  end

  def draw_flying(angle)
    (1..40-DART.size).each do |c|
      draw_arrow angle, c
      wait 0.01
    end
    wait 0.5
    getch
  end

  def exec
    Gorispace.new.dartspace(list)
  end
end
