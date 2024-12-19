import 'dart:html';
import 'dart:math';

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
  
  double secondsPassed = 0;
  Random random = Random();
  double seconds = 0;
  int randInt = 0;

  double unboundedLerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  void update(double deltaTime) {
    seconds += deltaTime;
    if (randInt < 9) {
      paddleY = unboundedLerp(paddleY, ballRef.y - paddleHeight / 2, 5 * deltaTime);
    }
    if (seconds > 0.2) {
      seconds = 0;
      randInt = random.nextInt(10);
    }
  }
}

class Ball {
  Ball({required this.speedX, required this.speedY, required this.radius});

  double speedX;
  double speedY;
  final double radius;
  
  double x = 0;
  double y = 0;
}

void main() {
  var normalButton = querySelector("#normalButton") as ButtonElement;
  var aiButton = querySelector("#aiButton") as ButtonElement;
  normalButton.onClick.listen((MouseEvent event) {
    game(Gamemode.normal);
    normalButton.disabled = true;
    aiButton.disabled = false;
  });
  aiButton.onClick.listen((MouseEvent event) {
    game(Gamemode.ai);
    normalButton.disabled = false;
    aiButton.disabled = true;
  });
}

void game(Gamemode gamemode) {
  (querySelector("#gamemodeLabel") as LabelElement).innerHtml = "Gamemode: ${gamemode.name.toUpperCase()}";
  DateTime previousTime = DateTime.now();

  final CanvasElement canvas = querySelector('#gameCanvas') as CanvasElement;
  final CanvasRenderingContext2D ctx = canvas.context2D;

  final Element player1ScoreElement = querySelector('#player1Score')!;
  final Element player2ScoreElement = querySelector('#player2Score')!;

  final int padding = 20;

  late int canvasWidth;
  late int canvasHeight;

  Ball ball = Ball(speedX: 3, speedY: 2, radius: 10);
  Player player1 = HumanPlayer(paddleWidth: 20, paddleHeight: 100, keyUpName: "w", keyDownName: "s");
  Player player2 = gamemode == Gamemode.normal
                  ? HumanPlayer(paddleWidth: 20, paddleHeight: 100, keyUpName: "ArrowUp", keyDownName: "ArrowDown")
                  : AIPlayer(paddleWidth: 20, paddleHeight: 100, ballRef: ball);
  
  void resetGame() {
    ball.x = canvasWidth / 2;
    ball.y = canvasHeight / 2;
    ball.speedX = 3;
    ball.speedY = 2;
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

    ball.x = canvasWidth / 2;
    ball.y = canvasHeight / 2;
  }

  void update() {
    final DateTime currentTime = DateTime.now();
    final double deltaTime = currentTime.difference(previousTime).inMilliseconds / 1000.0;
    previousTime = currentTime;

    player1.update(deltaTime);
    player2.update(deltaTime);
    
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);

    ctx.beginPath();
    ctx.arc(ball.x, ball.y, ball.radius, 0, 3.14 * 2);
    ctx.fillStyle = 'white';
    ctx.fill();
    ctx.closePath();

    ctx.fillStyle = 'white';
    ctx.fillRect(player1.paddleX, player1.paddleY, player1.paddleWidth, player1.paddleHeight); // Player 1
    ctx.fillRect(player2.paddleX, player2.paddleY, player2.paddleWidth, player2.paddleHeight); // Player 2

    ball.x += ball.speedX;
    ball.y += ball.speedY;

    if (ball.y + ball.radius > canvasHeight || ball.y - ball.radius < 0) {
      ball.speedY = -ball.speedY;
    }

    if (ball.x - ball.radius < player1.paddleX + player1.paddleWidth &&
        ball.y > player1.paddleY &&
        ball.y < player1.paddleY + player1.paddleHeight) {
      ball.speedX = -ball.speedX;
    }
    if (ball.x + ball.radius > player2.paddleX &&
        ball.y > player2.paddleY &&
        ball.y < player2.paddleY + player2.paddleHeight) {
      ball.speedX = -ball.speedX;
    }

    if (ball.x - ball.radius < 0) {
      player2.score++;
      updateScores();
      resetGame();
    }
    if (ball.x + ball.radius > canvasWidth) {
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
