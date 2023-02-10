
class ProgramWidget extends Widget {
  private final Program program;
  private final float cellSize;
  private int hoveringRow = -1;
  private int hoveringCol = -1;
  private boolean autorun = false;
  
  ProgramWidget(float x, float y, float cellSize, Program program) {
    super(x, y);
    this.program = program;
    this.cellSize = cellSize;
  }
  
  // Draw the program grid
  void draw() {
    pushMatrix();
    transform();

    for (int i=0; i < program.columns; ++i) {
      for (int j=0; j < program.rows; ++j) {
        final boolean current = i == program.executingRow && j == program.executingCol;
        
        pushMatrix();
        translate(i * cellSize, j * cellSize);
        stroke(46, 46, 46);
        strokeWeight(2);
        if (current) {
          switch (program.state) {
            case READY:
              fill(80, 150, 50);
              break;
            case RUNNING:
             fill(100, 255, 50);
             break;
            case TERMINATED:
             fill(50, 100, 100);
             break;
            case ERROR:
             fill(255, 50, 50);
             break;
          }
        } else if (i == hoveringRow && j == hoveringCol) {
          fill(200, 200, 200);
        } else {
          fill(255, 255, 255);
        }
        square(0, 0, cellSize);
        if (i == program.originRow && j == program.originCol) {
          square(5, 5, cellSize - 10);
        }
        
        final Instruction instr = program.grid[i][j];
        String cellText;
        switch (instr) {
          case PUSH:
            cellText = String.valueOf(program.push_data[i][j]);
            break;
          case EMPTY:
            cellText = "";
            break;
          case ADD:
            cellText = "+";
            break;
          case SUB:
            cellText = "-";
            break;
          case MUL:
            cellText = "*";
            break;       
          case DIV:
            cellText = "/";
            break;       
          case MOD:
            cellText = "%";
            break;       
          case EQ:
            cellText = "=";
            break;
          case NE:
            cellText = "!=";
            break;
          case LT:
            cellText = "<";
            break;
          case LE:
            cellText = "<=";
            break;
          case GT:
            cellText = ">";
            break;
          case GE:
            cellText = ">=";
            break;
          case NOOP:
            cellText = "";
            break;
          default:
            cellText = instr.toString();
        }

        textAlign(CENTER, CENTER);
        fill(0);
        text(cellText, cellSize/2, cellSize/2);
        
        final DirectionMode mode = directionMode(instr);
        if (mode != DirectionMode.SINK) {
          noStroke();
          pushMatrix();
          translate(cellSize/2, cellSize/2);
          
          fill(40, 175, 176);
          pushMatrix();
          rotate(rotation(program.direction_1[i][j]));
          translate(cellSize/2 - 5, 0);
          triangle(-10, -10, -10, 10, 0, 0);
          popMatrix();
          
          if (mode == DirectionMode.SPLIT) {
            fill(180, 67, 108);
            pushMatrix();
            rotate(rotation(program.direction_2[i][j]));
            translate(cellSize/2 - 5, 0);
            triangle(-10, -10, -10, 10, 0, 0);
            popMatrix();
          }
          
          popMatrix();
        }
        
        popMatrix();
      }
    }
    popMatrix();
  }
  
  void update() {
    final float mX = mouseX();
    final float mY = mouseY();
    
    final int i = floor(mX / cellSize);
    final int j = floor(mY / cellSize);
    
    if (i >= 0 && i < program.columns && j >= 0 && j < program.rows) {
      hoveringRow = i;
      hoveringCol = j;
    } else {
      hoveringRow = -1;
      hoveringCol = -1;
    }
    
    if (autorun) {
      program.step();
      
      if (program.state == ProgramState.TERMINATED || program.state == ProgramState.ERROR) {
        autorun = false;
      }
    }
  }
    
  boolean keyPressed() {
    switch (key) {
      case ' ':
        autorun = !autorun;
        break;
      case 'n':
      case 'N':
        program.step();
        autorun = false;
        return true;
      case 'r':
      case 'R':
        program.reset();
        autorun = false;
        return true;
      case 'c':
      case 'C':
        program.reset();
        program.clear();
        autorun = false;
        return true;
    }
    return false;
  }
  
  boolean mouseClicked() {    
    final int i = hoveringRow;
    final int j = hoveringCol;
    
    class InputInstruction implements InputListener {
      private final Program program;
      private final int i, j;
      private Instruction old;
      
      InputInstruction(Program program, int i, int j) {
        this.program = program;
        this.i = i;
        this.j = j;
        old = program.grid[i][j];
        program.grid[i][j] = Instruction.EMPTY;
      }
      
      void completed(String text) {
          try {  
            program.push_data[i][j] = Float.parseFloat(text);
            program.grid[i][j] = Instruction.PUSH;
            return;
          } catch(NumberFormatException e) { }

          Instruction instr;
          if (text == ">") {
            instr = Instruction.GT;
          } else if (text == ">=") {
            instr = Instruction.GE;
          } else if (text == "<") {
            instr = Instruction.LT;
          } else if (text == "<=") {
            instr = Instruction.LE;
          } else if (text == "=") {
            instr = Instruction.EQ;
          } else if (text == "!=") {
            instr = Instruction.NE;
          } else if (text == "") {
            instr = Instruction.EMPTY;
          } else if (text == ".") {
            instr = Instruction.NOOP;
          } else if (text == "*") {
            instr = Instruction.MUL;
          } else if (text == "+") {
            instr = Instruction.ADD;
          } else if (text == "/") {
            instr = Instruction.DIV;
          } else if (text == "-") {
            instr = Instruction.SUB;
          } else {
            try {
              instr = Instruction.valueOf(text.toUpperCase());
            } catch (IllegalArgumentException e) {
              println("Invalid instruction: " + text);
              instr = old;
            }
          }
          
          program.grid[i][j] = instr;
      }
      
      void cancelled() {
        program.grid[i][j] = old;
      }
    }
    
    if (i >= 0 && i < program.columns && j >= 0 && j < program.rows) {
      if (mouseButton == LEFT) {
        parent.addLast(styled(new InputDialog(i * cellSize + cellSize/2, j * cellSize + cellSize/2, "", new InputInstruction(program, i, j)),
                            () -> { fill(0); textAlign(CENTER, CENTER); }));
      } else if (mouseButton == RIGHT) {
        switch (directionMode(program.grid[i][j])) {
          case SINK:
           return false;
          case SINGLE:
           program.direction_1[i][j] = nextClockwise(program.direction_1[i][j]);
           break;
          case SPLIT:
           program.direction_1[i][j] = nextClockwise(program.direction_1[i][j]);
           if (program.direction_1[i][j] == program.direction_2[i][j]) {
             program.direction_1[i][j] = nextClockwise(nextClockwise(program.direction_1[i][j]));
             program.direction_2[i][j] = nextClockwise(program.direction_2[i][j]);
           }
           break;
        }
      }
      return true;
    }
    
    return false;
  }
}

class InputTextWidget extends DynamicTextWidget {
  
  final private Program program;
 
  InputTextWidget(float x, float y, Program program) {
    super(x, y);
    this.program = program;
  }
  
  String getText() {
    String inputText = "INPUT: ";
    for (int i = 0; i < program.input.size(); ++i) {
      final float v = program.input.get(i);
      if (i == program.inputCursor) {
        inputText += "[" + String.valueOf(v) + "] ";
      } else {
        inputText += String.valueOf(v) + " ";
      }
    }
    return inputText;
  }
}

class OutputTextWidget extends DynamicTextWidget {
  
  final private Program program;
 
  OutputTextWidget(float x, float y, Program program) {
    super(x, y);
    this.program = program;
  }
  
  String getText() {
    String text = "OUTPUT: ";
    for (float v : program.output) {
      text += String.valueOf(v) + " ";
    }
    return text;
  }
}

class ErrorMessagetWidget extends DynamicTextWidget {
  
  final private Program program;
 
  ErrorMessagetWidget(float x, float y, Program program) {
    super(x, y);
    this.program = program;
  }
  
  String getText() {
    return program.errorMessage;
  }
}

class StackWidget extends Widget {
  
  final private Program program;
 
  StackWidget(float x, float y, Program program) {
    super(x, y);
    this.program = program;
  }
  
  void draw() {
    final int MAX_SIZE = 20;
    final int LINE_SIZE = 15;
    
    pushMatrix();
    transform();

    stroke(242, 212, 146);
    noFill();
    rect(-5, 0, 100, MAX_SIZE*LINE_SIZE);

    textAlign(LEFT, BOTTOM);
    fill(242, 212, 146);
    text("STACK:", 0, 0);

    translate(0, (MAX_SIZE - program.stack.size()) * LINE_SIZE);
    
    for (int i = program.stack.size()-1; i >=0; --i) {
      text(String.valueOf(program.stack.get(i)), 0, 0);
      translate(0, LINE_SIZE);
    }

    popMatrix();
  }
}

// -------------------------------
// Examples
// -------------------------------

Program example1() {
  // empty
  Program p = new Program(11, 9, 8, 2);
  
  float[] input = {2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20};
  p.setInput(input);
  
  return p;
}

Program example2() {
  // cat
  Program p = new Program(11, 9, 5, 4);
  
  float[] input = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20};
  p.setInput(input);
  
  p.setInst(5, 4, Instruction.EOF, Direction.UP)
   .setCond(5, 3, Direction.RIGHT, Direction.LEFT)
   .setInst(6, 3, Instruction.HALT)
   .setInst(4, 3, Instruction.READ, Direction.DOWN)
   .setInst(4, 4, Instruction.WRITE, Direction.RIGHT);
  
  return p;
}

Program example3() {
  // SQRT
  Program p = new Program(6, 5, 5, 2);
  
  float[] input = {9, 2, 3, 100};
  p.setInput(input);
  
  p.setInst(5, 2, Instruction.EOF, Direction.UP);
  p.setCond(5, 1, Direction.LEFT, Direction.UP);
  p.setInst(4, 1, Instruction.HALT);

  p.setInst(5, 0, Instruction.READ, Direction.LEFT);
  p.setPush(4, 0, 1.0, Direction.LEFT);
  p.setInst(3, 0, Instruction.OVER, Direction.LEFT);
  p.setInst(2, 0, Instruction.OVER, Direction.LEFT);
  p.setInst(1, 0, Instruction.DUP, Direction.LEFT);
  p.setInst(0, 0, Instruction.MUL, Direction.DOWN);
  p.setInst(0, 1, Instruction.SUB, Direction.DOWN);
  p.setInst(0, 2, Instruction.ABS, Direction.DOWN);
  p.setPush(0, 3, 0.001, Direction.DOWN);
  p.setInst(0, 4, Instruction.GE, Direction.RIGHT);
  p.setCond(1, 4, Direction.RIGHT, Direction.UP);
  p.setInst(2, 4, Instruction.NOOP, Direction.RIGHT);
  p.setInst(3, 4, Instruction.NOOP, Direction.RIGHT);
  p.setInst(4, 4, Instruction.NOOP, Direction.RIGHT);
  p.setInst(5, 4, Instruction.WRITE, Direction.UP);
  p.setInst(5, 3, Instruction.NOOP, Direction.UP);
  
  p.setInst(1, 3, Instruction.OVER, Direction.RIGHT);
  p.setInst(2, 3, Instruction.OVER, Direction.RIGHT);
  p.setInst(3, 3, Instruction.SWAP, Direction.RIGHT);
  p.setInst(4, 3, Instruction.DIV, Direction.UP);
  p.setInst(4, 2, Instruction.ADD, Direction.LEFT);
  p.setPush(3, 2, 0.5, Direction.UP);
  p.setInst(3, 1, Instruction.MUL, Direction.UP);

  return p;
}

Program example4() {
  // PRIMES
  Program p = new Program(11, 3, 10, 0);
  
  p.setPush(10, 0, 2.0, Direction.LEFT)
   .setPush(9, 0, 1.0, Direction.LEFT)
   .setInst(8, 0, Instruction.ADD, Direction.LEFT)
   .setInst(7, 0, Instruction.DUP, Direction.LEFT)
   .setInst(6, 0, Instruction.DUP, Direction.LEFT)
   .setPush(5, 0, -1.0, Direction.LEFT)
   .setInst(4, 0, Instruction.NOOP, Direction.LEFT)
   .setInst(3, 0, Instruction.ADD, Direction.LEFT)
   .setInst(2, 0, Instruction.DUP, Direction.LEFT)
   .setPush(1, 0, 1.0, Direction.LEFT)
   .setInst(0, 0, Instruction.EQ, Direction.DOWN)
   .setCond(0, 1, Direction.DOWN, Direction.RIGHT)
   .setInst(1, 1, Instruction.OVER, Direction.RIGHT)
   .setInst(2, 1, Instruction.OVER, Direction.RIGHT)
   .setInst(3, 1, Instruction.SWAP, Direction.RIGHT)
   .setInst(4, 1, Instruction.MOD, Direction.RIGHT)
   .setCond(5, 1, Direction.UP, Direction.RIGHT)
   .setInst(6, 1, Instruction.DROP, Direction.RIGHT)
   .setInst(7, 1, Instruction.DROP, Direction.DOWN)
   .setInst(0, 2, Instruction.DROP, Direction.RIGHT)
   .setInst(1, 2, Instruction.WRITE, Direction.RIGHT)
   .setInst(2, 2, Instruction.NOOP, Direction.RIGHT)
   .setInst(3, 2, Instruction.NOOP, Direction.RIGHT)
   .setInst(4, 2, Instruction.NOOP, Direction.RIGHT)
   .setInst(5, 2, Instruction.NOOP, Direction.RIGHT)
   .setInst(6, 2, Instruction.NOOP, Direction.RIGHT)
   .setInst(7, 2, Instruction.NOOP, Direction.RIGHT)
   .setInst(8, 2, Instruction.NOOP, Direction.RIGHT)
   .setInst(9, 2, Instruction.NOOP, Direction.UP)
   .setInst(9, 1, Instruction.NOOP, Direction.UP);
  
  return p;
}

WidgetContainer main = new WidgetContainer(20, 20);

// --------------
// Processing API
// --------------
void setup() {
  final int CELL_SIZE = 70;
  size(1024, 768);
  
  Program program = example4();

  main.addLast(new ProgramWidget(0, 0, CELL_SIZE, program))
      .addLast(styled(new StaticTextWidget(0, program.rows * CELL_SIZE + 20, "R: reset, N: next, SPACE: pause/run, C: clear"),
                      () -> {fill(255, 255, 255); textAlign(LEFT, BOTTOM); }))
      .addLast(new StackWidget(program.columns * CELL_SIZE + 20, 0, program))
      .addLast(styled(new InputTextWidget(0, program.rows * CELL_SIZE + 60, program),
                      () -> { fill(255, 0, 255); textAlign(LEFT, BOTTOM); }))
      .addLast(styled(new OutputTextWidget(0, program.rows * CELL_SIZE + 80, program),
                      () -> { fill(255, 0, 255); textAlign(LEFT, BOTTOM); }))
      .addLast(styled(new ErrorMessagetWidget(0, program.rows * CELL_SIZE + 100, program),
                      () -> { fill(255, 0, 0); textAlign(LEFT, BOTTOM); }));
}

void draw() {
  main.update();

  background(46, 46, 46);
  
  main.draw();
}

void keyPressed() {
  main.keyPressed();
}

void mouseClicked() {
  main.mouseClicked();
}
