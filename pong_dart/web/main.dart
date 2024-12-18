import 'dart:html';

enum Gamemode {
  normal,
  ai,
}

abstract class Player {
  Player({required this.paddleWidth, required this.paddleHeight});

  int score = 0;

  final double paddleWidth;
  final double paddleHeight;
  
  double paddleX = 0;
  late double paddleY;

  bool goingUp = false;
  bool goingDown = false;

  void update(double deltaTime);
}

class HumanPlayer extends Player {
  HumanPlayer({required this.keyUpName, required this.keyDownName, required super.paddleWidth, required super.paddleHeight})
  {
    document.onKeyUp.listen((KeyboardEvent event) {
      if (event.key == keyUpName) {
        goingUp = false;
      } else if (event.key == keyDownName) {
        goingDown = false;
      }
    });

    document.onKeyDown.listen((KeyboardEvent event) {
      if (event.key == keyUpName) {
        goingUp = true;
      } else if (event.key == keyDownName) {
        goingDown = true;
      }
    });
  }

  final String keyUpName;
  final String keyDownName;
  
  @override
  void update(double deltaTime) {}
}

class AIPlayer extends Player {
  AIPlayer({required this.ballRef, required super.paddleWidth, required super.paddleHeight});
  
  final Ball ballRef;
  
  @override
  void update(double deltaTime) {
    paddleY = ballRef.ballY - paddleHeight/2;
  }
}

class Ball {
  double ballX = 0;
  double ballY = 0;
  double ballSpeedX = 3;
  double ballSpeedY = 2;
  final double ballRadius = 10;
}

void main() async {  
  DateTime previousTime = DateTime.now();

  final CanvasElement canvas = querySelector('#gameCanvas') as CanvasElement;
  final CanvasRenderingContext2D ctx = canvas.context2D;

  final Element player1ScoreElement = querySelector('#player1Score')!;
  final Element player2ScoreElement = querySelector('#player2Score')!;

  final int padding = 20;

  Gamemode gamemode = Gamemode.ai;

  late int canvasWidth;
  late int canvasHeight;

  Ball ball = Ball();
  Player player1 = HumanPlayer(paddleWidth: 20, paddleHeight: 100, keyUpName: "w", keyDownName: "s");
  Player player2 = gamemode == Gamemode.normal
                  ? HumanPlayer(paddleWidth: 20, paddleHeight: 100, keyUpName: "ArrowUp", keyDownName: "ArrowDown")
                  : AIPlayer(paddleWidth: 20, paddleHeight: 100, ballRef: ball);
  
  void resetGame() {
    ball.ballX = canvasWidth / 2;
    ball.ballY = canvasHeight / 2;
    ball.ballSpeedX = 3;
    ball.ballSpeedY = 2;
  }

  void updateScores() {
    player1ScoreElement.text = 'Player 1: ${player1.score}';
    player2ScoreElement.text = 'Player 2: ${player2.score}';
  }

  void resizeGame() {
    canvasWidth = window.innerWidth! - 2 * padding;
    canvasHeight = window.innerHeight! - 100 - 2 * padding;
    canvas.width = canvasWidth;
    canvas.height = canvasHeight;

    player1.paddleX = padding.toDouble();
    player1.paddleY = (canvasHeight - player1.paddleHeight) / 2;
    player2.paddleX = canvasWidth - player2.paddleWidth - padding.toDouble();
    player2.paddleY = (canvasHeight - player2.paddleHeight) / 2;

    ball.ballX = canvasWidth / 2;
    ball.ballY = canvasHeight / 2;
  }

  void update() {
    final DateTime currentTime = DateTime.now();
    final double deltaTime = currentTime.difference(previousTime).inMilliseconds / 1000.0;
    previousTime = currentTime;

    player1.update(deltaTime);
    player2.update(deltaTime);
    
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    ctx.beginPath();
    ctx.arc(ball.ballX, ball.ballY, ball.ballRadius, 0, 3.14 * 2);
    ctx.fillStyle = 'white';
    ctx.fill();
    ctx.closePath();

    ctx.fillStyle = 'white';
    ctx.fillRect(player1.paddleX, player1.paddleY, player1.paddleWidth, player1.paddleHeight); // Player 1
    ctx.fillRect(player2.paddleX, player2.paddleY, player2.paddleWidth, player2.paddleHeight); // Player 2

    ball.ballX += ball.ballSpeedX;
    ball.ballY += ball.ballSpeedY;

    if (ball.ballY + ball.ballRadius > canvasHeight || ball.ballY - ball.ballRadius < 0) {
      ball.ballSpeedY = -ball.ballSpeedY;
    }

    if (ball.ballX - ball.ballRadius < player1.paddleX + player1.paddleWidth &&
        ball.ballY > player1.paddleY &&
        ball.ballY < player1.paddleY + player1.paddleHeight) {
      ball.ballSpeedX = -ball.ballSpeedX;
    }
    if (ball.ballX + ball.ballRadius > player2.paddleX &&
        ball.ballY > player2.paddleY &&
        ball.ballY < player2.paddleY + player2.paddleHeight) {
      ball.ballSpeedX = -ball.ballSpeedX;
    }

    if (ball.ballX - ball.ballRadius < 0) {
      player2.score++;
      updateScores();
      resetGame();
    }
    if (ball.ballX + ball.ballRadius > canvasWidth) {
      player1.score++;
      updateScores();
      resetGame();
    }

    // Player 1
    if (player1.goingUp && player1.paddleY > 0) {
      player1.paddleY -= 5;
    }
    if (player1.goingDown && player1.paddleY + player1.paddleHeight < canvasHeight) {
      player1.paddleY += 5;
    }

    // Player 2
    if (player2.goingUp && player2.paddleY > 0) {
      player2.paddleY -= 5;
    }
    if (player2.goingDown && player2.paddleY + player2.paddleHeight < canvasHeight) {
      player2.paddleY += 5;
    }

    window.animationFrame.then((_) => update());
  }

  resizeGame();
  updateScores();
  window.onResize.listen((_) => resizeGame());
  update();
}
