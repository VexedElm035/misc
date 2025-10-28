let snake =[ {x:150, y:150}, {x:140, y:150}, {x:130, y:150}, {x:120, y:150} ];
const refreshRate = 125;
const velocity = 10;
let dx = velocity;
let dy = 0;
let score = 0;
let highscore = 0;
let game = 1;
let changingDirection = false;

const gameCanvas = document.getElementById("gameCanvas");
const ctx = gameCanvas.getContext("2d");

function clearCanvas() {
    ctx.fillStyle = 'white';
    ctx.strokStyle = 'black';
    ctx.fillRect(0, 0, gameCanvas.width, gameCanvas.height);
    ctx.strokeRect(0, 0, gameCanvas.width, gameCanvas.height);
};

function drawSnakePart(snakePart) {
    const smoothtness = 2; //1-10
    const index = snake.indexOf(snakePart);
    const total = snake.length;
    const t = index / (total - 1);
    let lightness;
    let hue = (index * smoothtness) % 360;
    lightness = 50 - (index * 25 / (total - 1)); // 50% to 25%
    ctx.fillStyle = `hsl(${hue}, 70%, ${lightness}%)`
    ctx.strokeStyle = `hsl(${hue}, 70%, ${lightness}%)`;
    ctx.fillRect(snakePart.x, snakePart.y, velocity, velocity);
    ctx.strokeRect(snakePart.x, snakePart.y, velocity, velocity);
};

function drawSnake(){
    createFood();
    const intervalId = setInterval(() => {
        if (game === 0) {
            clearInterval(intervalId);
            return;
        }
        main();
        if (!game) {
            showRestart();
        } else {
            hideRestart();
        }
    }, refreshRate);
    
};

function advanceSnake() {
    const head = {x: snake[0].x + dx, y: snake[0].y + dy};
    snake.unshift(head);
    const didEatFood = snake[0].x === foodX && snake[0].y === foodY;
    if (didEatFood) {
        score += 1;
        document.getElementById("score").innerText = score;
        createFood();
    } else {
        snake.pop();
    }
};

function changeDirection(event) {
    const LEFT_KEY = 65;
    const RIGHT_KEY = 68;
    
    if (changingDirection) return;
    const keyPressed = event.keyCode;
    const goingUp = dy === -velocity;
    const goingDown = dy === velocity;
    const goingRight = dx === velocity;
    const goingLeft = dx === -velocity;
    if (keyPressed === RIGHT_KEY && goingRight) {
        dx = 0;
        dy = velocity;
        changingDirection = true;
    } else if (keyPressed === RIGHT_KEY && goingDown) {
        dx = -velocity;
        dy = 0;
        changingDirection = true;
    } else if (keyPressed === RIGHT_KEY && goingLeft) {
        dx = 0;
        dy = -velocity;
        changingDirection = true;
    } else if (keyPressed === RIGHT_KEY && goingUp) {
        dx = velocity;
        dy = 0;
        changingDirection = true;
    }
    if (keyPressed === LEFT_KEY && goingRight) {
        dx = 0;
        dy = -velocity;
        changingDirection = true;
    } else if (keyPressed === LEFT_KEY && goingUp) {
        dx = -velocity;
        dy = 0;
        changingDirection = true;
    } else if (keyPressed === LEFT_KEY && goingLeft) {
        dx = 0;
        dy = velocity;
        changingDirection = true;
    } else if (keyPressed === LEFT_KEY && goingDown) {
        dx = velocity;
        dy = 0;
        changingDirection = true;
    }
}

function randomTen(min, max) {
    return Math.round((Math.random() * (max - min) + min) / velocity) * velocity;
};

function createFood() {
    foodX = randomTen(0, gameCanvas.width - velocity);
    foodY = randomTen(0, gameCanvas.height - velocity);
    snake.forEach(function isFoodOnSnake(part){
        const foodIsOnSnake = part.x == foodX && part.y == foodY;
        if (foodIsOnSnake) {
            createFood();
        };
    });
};

function drawFood() {
    ctx.fillStyle = 'red';
    ctx.strokeStyle = 'darkred';
    ctx.fillRect(foodX, foodY, velocity, velocity);
    ctx.strokeRect(foodX, foodY, velocity, velocity);
}

function didGameEnd() {
    for (let i = 1; i < snake.length; i++) {
        const didColide = snake[i].x === snake[0].x && snake[i].y === snake[0].y;
        if (didColide) {
            return didColide;
        }
    }
    const hitLeftWall = snake[0].x < 0;
    const hitRightWall = snake[0].x > gameCanvas.width - velocity;
    const hitTopWall = snake[0].y < 0;
    const hitBottomWall = snake[0].y > gameCanvas.height - velocity;
    return hitLeftWall || hitRightWall || hitTopWall || hitBottomWall;
}

function main(){
    if (didGameEnd()){
        highscore = score < highscore ? highscore : score;
        document.getElementById("highscore").innerText = highscore;
        game = 0;
        return ;
    }

    clearCanvas();
    drawFood();
    changingDirection = false
    advanceSnake();
    snake.forEach(drawSnakePart);
}

function showRestart() {
    document.getElementById("restartButtonDiv").innerHTML = `<button id="restartButton">Reiniciar</button>`;
    document.getElementById("restartButton").addEventListener("click", function() {
        snake = [{x:150, y:150}, {x:140, y:150}, {x:130, y:150}, {x:120, y:150}];
        dx = velocity;
        dy = 0;
        score = 0;
        document.getElementById("highscore").innerText = highscore;
        game = 1;
        drawSnake()
    });
}

function hideRestart() {
    document.getElementById("restartButtonDiv").innerHTML = "";
}

drawSnake()
document.addEventListener("keydown", changeDirection);

ctx.stroke();