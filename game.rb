require 'gosu'

class StartPage < Gosu::Window
  def initialize
    super(1000, 800)
    self.caption = "Pong 1.0 Binnatov Edition"
    @font = Gosu::Font.new(40)
    @options = ["Multiplayer", "AI player"]
    @current_option = 0
  end

  def draw
    # Background color
    Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK)

    # The game title
    @font.draw_text("WELCOME TO PONG 6001 BINNATOV EDITION", 125, 250, 0, 1.0, 1.0, Gosu::Color::WHITE)

    # Display instructions
    @font.draw_text("CHOOSE A GAME MODE AND PRESS ENTER TO START", 30, 350, 0, 1.0, 1.0, Gosu::Color::WHITE)

    # Display options
    @options.each_with_index do |option, i|
      color = Gosu::Color::WHITE
      if @current_option == i
        color = Gosu::Color::YELLOW
      end
      @font.draw_text(option, 425, 450 + i * 50, 0, 1.0, 1.0, color)
    end
  end

  def update
    if Gosu.button_down?(Gosu::KB_RETURN)
      if @current_option == 0
        close
      elsif @current_option == 1
        close
        @game_window = GameWindow.new
        @game_window.show
      end
    end
    
    if Gosu.button_down?(Gosu::KB_UP)
      @current_option = (@current_option - 1) % @options.length
    end
    if Gosu.button_down?(Gosu::KB_DOWN)
      @current_option = (@current_option + 1) % @options.length
    end
  end
end

class GameWindow < Gosu::Window
  attr_reader :score
  SCORE_LIMIT = 3
  
  def initialize
    super(1000,800)
    self.caption = "Pong Game (Binnatov Edition)"
    margin = 40

    @player = Paddle.new( margin, margin )

    @last_mouse_y = margin

    @enemy = Paddle.new( self.width - Paddle::WIDTH - margin, margin)

    @ball = Ball.new( 100, 100, { :x => 10, :y => 5 }) 
    
    @score = [0, 0]
      
    @font = Gosu::Font.new(20)
      
    @flash = {}
      
    @counter = 0

    @game_over = false
  end
  
  def button_down(id)
    case id
    when Gosu::KbEscape
      close
    end
  end
  
  def update
    player_move
    ai_move
    @ball.update
    
    if @ball.collide?(@player)
      
      @ball.reflect_horizontal
        increase_speed 
  
      elsif @ball.collide?(@enemy)
        @ball.reflect_horizontal
        increase_speed 
  
      elsif @ball.x <= 0
        @ball.x = @player.right
        score[1] += 1
        @ball.v[:x] = 4
        flash_side(:left)
  
      elsif @ball.right >= self.width
        @ball.x = @enemy.left
        score[0] += 1
        @ball.v[:x] = -4
        flash_side(:right)
      end

      if score[0] >= SCORE_LIMIT || score[1] >= SCORE_LIMIT
        show_winner
        close
      end

      @ball.reflect_vertical if @ball.y < 0 || @ball.bottom > self.height
    end
    
    def show_winner
      if score[0] >= SCORE_LIMIT
        @winner_window = WinnerWindow.new("You win", @game_over)
      elsif score[1] >= SCORE_LIMIT
        @winner_window = WinnerWindow.new("You lose", @game_over)
      end
      @winner_window.show
    end

    class WinnerWindow < Gosu::Window
      def initialize(winner, game_over)
        super(1000,800)
        self.caption = "Pong Game (Binnatov Edition)"
        @font = Gosu::Font.new(48)
        @winner = winner
        @game_over = game_over
      end

      def draw
        Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK)
        @font.draw_text(@winner, 320, 350, 0, 1.0, 1.0, Gosu::Color::WHITE)

        if @game_over
          @game_over_window ||= WinnerWindow.new(score[0] >= SCORE_LIMIT ? "You win" : "You lose", @game_over)
        end
      end
    end

    def increase_speed
      @ball.v[:x] = @ball.v[:x] * 1.5
    end
  
    def player_move
      y = mouse_y
      diff = y - @last_mouse_y
      @player.y += diff
  
      @player.y = 0 if @player.y <= 0
      @player.bottom = self.height if @player.bottom >= self.height
  
      @last_mouse_y = y
    end
  
    def ai_move
      distance = @enemy.center_x - @ball.center_x
      if distance > self.width
        pct_move = 0.2
      elsif distance > self.width 
        pct_move = 0.05
      else
        pct_move = 0.14
      end
  
      diff = @ball.center_y - @enemy.center_y
      @enemy.y += diff * pct_move
  
      @enemy.top = 0 if @enemy.top <= 0
      @enemy.bottom = self.height if @enemy.bottom >= self.height
    end
  
    def flash_side(side)
      @flash[side] = true
    end
  
    def draw
      draw_background
  
      if @flash[:left]
        Gosu.draw_rect 0, 0, self.width / 2, self.height, Gosu::Color::RED
        @flash[:left] = nil
      end
  
      if @flash[:right]
        Gosu.draw_rect self.width / 2, 0, self.width, self.height, Gosu::Color::RED
        @flash[:right] = nil
      end
  
      draw_center_line
      draw_score
      @player.draw
      @enemy.draw
      @ball.draw
    end
  
    def draw_background
      Gosu.draw_rect 0, 0, self.width, self.height, Gosu::Color::BLACK
    end
  
    def draw_center_line
      center_x = self.width / 2
      segment_length = 20
      gap = 5
      color = Gosu::Color::WHITE
      y = 0
      begin
        draw_line(center_x, y, color,
                  center_x, y + segment_length, color)
        y += segment_length + gap
      end while y < self.height
    end
  
    def draw_score
      center_x = self.width / 2
      offset = 15
      char_width = 10
      z_order = 100
      @font.draw_text score[0].to_s, center_x - offset - char_width, offset, z_order
      @font.draw_text score[1].to_s, center_x + offset, offset, z_order
    end
  end

  class GameObject
    attr_accessor :x
    attr_accessor :y
    attr_accessor :w
    attr_accessor :h
  
    def initialize(x, y, w, h)
      @x = x
      @y = y
      @w = w
      @h = h
    end
  
    def left
      x
    end
  
    def right
      x + w
    end
  
    def right=(r)
      self.x = r - w
    end
  
    def top
      y
    end
  
    def top=(t)
      self.y = t
    end
  
    def bottom
      y + h
    end
  
    def center_y
      y + h/2
    end
  
    def center_x
      x + w/2
    end
  
    def bottom=(b)
      self.y = b - h
    end
  
    def collide?(other)
      x_overlap = [0, [right, other.right].min - [left, other.left].max].max
      y_overlap = [0, [bottom, other.bottom].min - [top, other.top].max].max
      x_overlap * y_overlap != 0
    end
  end
  
  class Ball < GameObject
    WIDTH = 5
    HEIGHT = 5
  
    attr_reader :v
    def initialize(x, y, v)
      super(x, y, WIDTH, HEIGHT)
      @v = v
    end
  
    def update
      self.x += v[:x]
      self.y += v[:y]
    end
  
    def reflect_horizontal
      v[:x] = -v[:x]
    end
  
    def reflect_vertical
      v[:y] = -v[:y]
    end
  
    def draw
      Gosu.draw_rect x, y, WIDTH, HEIGHT, Gosu::Color::RED
    end
  end
  
  class Paddle < GameObject
    WIDTH = 12
    HEIGHT = 60
  
    def initialize(x, y)
      super(x, y, WIDTH, HEIGHT)
    end
  
    def draw
      Gosu.draw_rect x, y, w, h, Gosu::Color::WHITE
    end
  end

# Create and show the StartPage
window1 = StartPage.new
window2 = GameWindow.new


window1.show
window2.show

