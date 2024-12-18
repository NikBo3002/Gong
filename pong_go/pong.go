package main

import (
	"bufio"
	"fmt"
	"os"
	"time"

	"github.com/eiannone/keyboard"
)

const (
	width      = 40
	height     = 10
	ballChar   = 'O'
	paddleChar = '|'
	emptySpace = ' '
	frameDelay = 100 * time.Millisecond
)

type Game struct {
	ballX, ballY       int
	ballDirX, ballDirY int
	paddle1Y, paddle2Y int
	score1, score2     int
}

func (g *Game) draw() {
	fmt.Print("\033[H\033[2J") // Clear screen
	for y := 0; y < height; y++ {
		for x := 0; x < width; x++ {
			switch {
			case x == g.ballX && y == g.ballY:
				fmt.Print(string(ballChar))
			case x == 0 && y >= g.paddle1Y && y < g.paddle1Y+3:
				fmt.Print(string(paddleChar))
			case x == width-1 && y >= g.paddle2Y && y < g.paddle2Y+3:
				fmt.Print(string(paddleChar))
			default:
				fmt.Print(string(emptySpace))
			}
		}
		fmt.Println()
	}
	fmt.Printf("Score: Player 1 = %d, Player 2 = %d\n", g.score1, g.score2)
	fmt.Println("Press 'w' to move up, 's' to move down, or 'q' to quit.")
}

func (g *Game) update() {
	// Update ball position
	g.ballX += g.ballDirX
	g.ballY += g.ballDirY

	// Ball collision with top or bottom walls
	if g.ballY <= 0 || g.ballY >= height-1 {
		g.ballDirY *= -1
	}

	// Ball collision with paddles
	if g.ballX == 1 && g.ballY >= g.paddle1Y && g.ballY < g.paddle1Y+3 {
		g.ballDirX *= -1
	} else if g.ballX == width-2 && g.ballY >= g.paddle2Y && g.ballY < g.paddle2Y+3 {
		g.ballDirX *= -1
	}

	// Ball out of bounds
	if g.ballX <= 0 {
		g.score2++
		g.resetBall()
	} else if g.ballX >= width-1 {
		g.score1++
		g.resetBall()
	}

	// AI paddle movement
	g.paddle2Y = g.ballY - 1
	if g.paddle2Y < 0 {
		g.paddle2Y = 0
	} else if g.paddle2Y > height-3 {
		g.paddle2Y = height - 3
	}
}

func (g *Game) update2() {
	// Update ball position
	g.ballX += g.ballDirX
	g.ballY += g.ballDirY

	// Ball collision with top or bottom walls
	if g.ballY <= 0 || g.ballY >= height-1 {
		g.ballDirY *= -1
	}

	// Ball collision with paddles
	if g.ballX == 1 && g.ballY >= g.paddle1Y && g.ballY < g.paddle1Y+3 {
		g.ballDirX *= -1
	} else if g.ballX == width-2 && g.ballY >= g.paddle2Y && g.ballY < g.paddle2Y+3 {
		g.ballDirX *= -1
	}

	// Ball out of bounds
	if g.ballX <= 0 {
		g.score2++
		g.resetBall()
	} else if g.ballX >= width-1 {
		g.score1++
		g.resetBall()
	}

}

func (g *Game) resetBall() {
	g.ballX, g.ballY = width/2, height/2
	g.ballDirX, g.ballDirY = -1, 1
}

func (g *Game) movePaddle(up bool) {
	if up && g.paddle1Y > 0 {
		g.paddle1Y--
	} else if !up && g.paddle1Y < height-3 {
		g.paddle1Y++
	}
}

func (g *Game) movePaddle2(up bool) {

	if up && g.paddle2Y > 0 {
		g.paddle2Y--
	} else if !up && g.paddle2Y < height-3 {
		g.paddle2Y++
	}
}

func main() {
	game := &Game{
		ballX:    width / 2,
		ballY:    height / 2,
		ballDirX: -1,
		ballDirY: 1,
		paddle1Y: height/2 - 1,
		paddle2Y: height/2 - 1,
	}

	// Initialize keyboard input
	if err := keyboard.Open(); err != nil {
		fmt.Println("Failed to open keyboard:", err)
		return
	}
	defer keyboard.Close()

	// Variable to control the game loop
	running := true

	// Get mode selection
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("1.AI\n2.PvP\nChoose mode: ")
	mode, _ := reader.ReadByte()

	// Main game loop
	go func() {
		for {
			char, _, err := keyboard.GetKey()
			if err != nil {
				fmt.Println("Error reading key:", err)
				break
			}
			switch char {
			case 'w':
				game.movePaddle(true)
			case 's':
				game.movePaddle(false)
			case 'o':
				if mode == '2' {
					game.movePaddle2(true)
				}
			case 'l':
				if mode == '2' {
					game.movePaddle2(false)
				}
			case 'q': // Break case to stop the game
				running = false
				return
			}
		}
	}()

	// Main game loop
	for running {
		if mode == '2' {
			game.update2()
			game.draw()
			time.Sleep(frameDelay)
		} else {
			game.update()
			game.draw()
			time.Sleep(frameDelay)
		}
	}

	fmt.Println("Game Over. Thanks for playing!")
}
