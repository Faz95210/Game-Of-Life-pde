int rowCount = 60;
int columnsCount = 100;
int windowWidth = 1000;
int windowHeight = 600;

float squareWidth = 50;
float squareHeight = 50;
boolean running = false;
final Grid grid = new Grid(rowCount, columnsCount);
int count = 0;


enum Status {
  Empty,
  Alive,
  Dead,
  Dying,
  Birthing, // English good
}

enum CauseOfDeath {
  Loneliness,
  Overpopulation,
  None
}

void setup() {  // setup() runs once
  size(1000, 1000);
  frameRate(30);
}

void draw() {  // draw() loops forever, until stopped
  background(204);
  count +=1;
  if (running && count > 10) {
    grid.processSquares();
  }
  if (count > 10) count = 0;
  grid.drawGrid();
}

void keyPressed() {
 if (key == ' ') {
   running = !running;
 } else if (key == 'c') {
   grid.initGrid();
 } else if (key == 'r') {
   grid.randomizeGrid();
 }
}

void mousePressed() {
  int squareX = floor(mouseX/ squareWidth);
  int squareY = floor(mouseY / squareHeight);

  if (squareX < grid.grid.length && squareY < grid.grid[squareX].length) {
    grid.grid[squareX][squareY].manualTrigger();
  }
}


class Square {

  Status status = Status.Empty;
  CauseOfDeath cod = CauseOfDeath.None;
  final float posX;
  final float posY;
  final float width;
  final float height;
  float squareColor = 0;
  float bordersColor = 250;
  int animationTick = 0;

  Square(final float posX, final float posY, final float width, final float height) {
    this.posX = posX;
    this.posY = posY;
    this.width = width;
    this.height = height;
  }

  void birth() {
    this.status = Status.Birthing;
    this.animationTick = 0;
    this.cod = CauseOfDeath.None;
  }

  void kill(final CauseOfDeath cod) {
    println("Died of "+ (cod == CauseOfDeath.Loneliness ? "Loneliness" : "Overpopulation") );
    this.status = Status.Dying;
    if (cod != null)
      this.cod = cod;
    this.animationTick = 0;
  }

  void manualTrigger() {
    switch (this.status) {
      case Empty:
      case Dying:
      case Dead:
        birth();
        break;
      case Birthing:
      case Alive:
        kill((random (100) % 2) == 0 ? CauseOfDeath.Loneliness : CauseOfDeath.Overpopulation);
        break;
    }
  }

  void drawSquare() {
    switch (status) {
      case Empty:
        squareColor = 0;
        bordersColor = 250;
        break;
      case Alive:
        squareColor = 250;
        bordersColor = 250;
        break;
      case Dead:
        squareColor = 0;
        bordersColor = 250;
        break;
      case Dying:
        // This square is dying so we draw it first so as to not override death animation.
        bordersColor = 250;
        squareColor -= 25;
        if (squareColor < 0) {
            animationTick = 0;
            squareColor = 0;
        } else {
          cod = CauseOfDeath.None;
          status = Status.Dead;
        }
        break;
      case Birthing:
        if (squareColor < 250)  {
          squareColor += 25;
          if (squareColor > 250) squareColor = 250;
        } else {
          status = Status.Alive;
        }
        bordersColor = 250;
        break;
      default:
      
        break;
    }
    fill(squareColor);
    stroke(bordersColor);
    rect(posX, posY, width, height);
  }

  boolean isAlive() {
    return this.status == Status.Alive || this.status == Status.Birthing;
  }

}

class Grid {

  final int rows;
  final int columns;
  final Square[][] grid;

  Grid(final int rows, final int columns) {
    this.rows = rows;
    this.columns = columns;
    grid = new Square[rows][columns]; 
    initGrid();
  }

  void initGrid() {
    for (int x = 0; x < columns; x++) {
      for (int y = 0; y < rows; y++) {
        grid[y][x] = new Square(squareHeight * y, squareWidth * x, squareWidth, squareHeight); 
      }
    }
  }

  //Shamelessly copied from the documentation.
  void randomizeGrid() {
    for (int x = 0; x < columns; x++) {
      for (int y = 0; y < rows; y++) {
        float state = random (100);
        grid[y][x] = new Square(squareHeight * y, squareWidth * x, squareWidth, squareHeight); 
        if (state < 15) {
          grid[y][x].birth();
        }
      }
    }
  }

  int calculateNeighbors(final int y, final int x) {
    int neighborsCount = 0;

    if (y > 0 && grid[y - 1][x].isAlive()) {
      neighborsCount++;
    }
    if (x > 0 && grid[y][x - 1].isAlive()) {neighborsCount++;}
    if (y > 0 && x > 0 && grid[y - 1][x - 1].isAlive()) {neighborsCount++;}
    if (y > 0 && x < grid[y - 1].length - 1 && grid[y - 1][x + 1].isAlive()) {neighborsCount++;}
    if (y < grid.length - 1 && grid[y + 1][x].isAlive()) {neighborsCount++;}
    if (y < grid.length - 1 && x < grid[y + 1].length - 1 && grid[y + 1][x + 1].isAlive()) {neighborsCount++;}
    if (x < grid[y].length -1 && grid[y][x + 1].isAlive()) {neighborsCount++;}
    if (y < grid.length - 1 && x > 0 && grid[y + 1][x - 1].isAlive()) {neighborsCount++;}
  
    return neighborsCount;
  }

  void processSquares() {
    ArrayList<Square> dyingSquares = new ArrayList<Square>();
    ArrayList<Square> newSquares = new ArrayList<Square>();


    for (int x = 0; x < columns; x++) {
      for (int y = 0; y < rows; y++) {
        final int neighborsCount = calculateNeighbors(y, x);
         switch (grid[y][x].status) {
          case Empty:
          case Dying:
          case Dead:
              if (neighborsCount == 3) {
                println("BIRTH");
                newSquares.add(grid[y][x]);
              }
            break;
          case Birthing:
          case Alive:
            if (neighborsCount  <= 1 || neighborsCount >= 4) {
              println(neighborsCount <= 1 ? "Die of loneliness" : "Die of overpopulation");
              grid[y][x].cod = neighborsCount <= 1 ? CauseOfDeath.Loneliness : CauseOfDeath.Overpopulation;
              dyingSquares.add(grid[y][x]);
            }
            break;
          default:
            grid[y][x].animationTick = 0;
            break;
        }
      }
    }
    for (final Square square : dyingSquares) {
      square.kill(null);
    }
    for (final Square square : newSquares) {
      square.birth();
    }
  }

  void drawGrid() {
    for (int x = 0; x < columns; x++) {
      for (int y = 0; y < rows; y++) {
        grid[y][x].drawSquare(); 
      }
    }
  }
}
