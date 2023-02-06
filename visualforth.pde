
class ProgramWidget extends Widget {
  
  private Program program;
  final float cellSize;
  private int hoverI = -1;
  private int hoverJ = -1;
  
  ProgramWidget(float x, float y, float cellSize, Program program) {
    super(x, y);
    this.program = program;
    this.cellSize = cellSize;
  }
  
  
  // Draw the program grid
  void draw() {
    pushMatrix();
    transform();

    for (int i=0; i < program.cells_x; ++i) {
      for (int j=0; j < program.cells_y; ++j) {
        final boolean current = i == program.current_x && j == program.current_y;
        
        pushMatrix();
        translate(i * cellSize, j * cellSize);
        stroke(0);
        if (current && program.state == ProgramState.RUNNING) {
          fill(100, 255, 50);
        } else if (current && program.state == ProgramState.ERROR) {
          fill(255, 50, 50);
        } else if (i == hoverI && j == hoverJ) {
          fill(200, 200, 200);
        } else {
          fill(255, 255, 255);
        }
        square(0, 0, cellSize);
        if (i == program.origin_x && j == program.origin_y) {
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
            cellText = ".";
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
          
          fill(0, 200, 0);
          pushMatrix();
          rotate(rotation(program.direction_1[i][j]));
          translate(cellSize/2 - 5, 0);
          triangle(-10, -10, -10, 10, 0, 0);
          popMatrix();
          
          if (mode == DirectionMode.SPLIT) {
            fill(200, 0, 0);
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
    final float mX = relativeMouseX();
    final float mY = relativeMouseY();
    
    final int i = floor(mX / cellSize);
    final int j = floor(mY / cellSize);
    
    if (i >= 0 && i < program.cells_x && j >= 0 && j < program.cells_y) {
      hoverI = i;
      hoverJ = j;
    } else {
      hoverI = -1;
      hoverJ = -1;
    }
    
    // TODO: run the program.
  }
    
  boolean keyPressed() {
    switch (key) {
      case ' ':
        program.step();
        return true;
      case 'r':
      case 'R':
        program.reset();
        return true;
    }
    return false;
  }
  
  boolean mouseClicked() {
    final float mX = relativeMouseX();
    final float mY = relativeMouseY();
    
    final int i = floor(mX / cellSize);
    final int j = floor(mY / cellSize);
    
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
    
    if (i >= 0 && i < program.cells_x && j >= 0 && j < program.cells_y) {
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
    String inputText = "Input: ";
    for (int i = 0; i < program.input.size(); ++i) {
      final float v = program.input.get(i);
      if (i == program.input_cursor) {
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
    String text = "Output: ";
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
    return program.error_message;
  }
}

class StackTextWidget extends DynamicTextWidget {
  
  final private Program program;
 
  StackTextWidget(float x, float y, Program program) {
    super(x, y);
    this.program = program;
  }
  
  String getText() {
    String stackText = "Stack: ";
    for (float v: program.stack) {
      stackText += String.valueOf(v) + " ";
    }
    return stackText;
  }
}

// -------------------------------
// Widgets
// -------------------------------

WidgetContainer main = new WidgetContainer(20, 20);

// -------------------------------
// Parameters
// -------------------------------

final int CELL_SIZE = 70;

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
  
  p.setInstr(5, 4, Instruction.EOF, Direction.UP);
  p.setConditional(5, 3, Direction.RIGHT, Direction.LEFT);
  p.setInstr(6, 3, Instruction.HALT);
  p.setInstr(4, 3, Instruction.READ, Direction.DOWN);
  p.setInstr(4, 4, Instruction.WRITE, Direction.RIGHT);
  
  return p;
}

Program example3() {
  // SQRT
  Program p = new Program(6, 5, 5, 2);
  
  float[] input = {9, 2, 3, 100};
  p.setInput(input);
  
  p.setInstr(5, 2, Instruction.EOF, Direction.UP);
  p.setConditional(5, 1, Direction.LEFT, Direction.UP);
  p.setInstr(4, 1, Instruction.HALT);

  p.setInstr(5, 0, Instruction.READ, Direction.LEFT);
  p.setPushData(4, 0, 1.0, Direction.LEFT);
  p.setInstr(3, 0, Instruction.OVER, Direction.LEFT);
  p.setInstr(2, 0, Instruction.OVER, Direction.LEFT);
  p.setInstr(1, 0, Instruction.DUP, Direction.LEFT);
  p.setInstr(0, 0, Instruction.MUL, Direction.DOWN);
  p.setInstr(0, 1, Instruction.SUB, Direction.DOWN);
  p.setInstr(0, 2, Instruction.ABS, Direction.DOWN);
  p.setPushData(0, 3, 0.001, Direction.DOWN);
  p.setInstr(0, 4, Instruction.GE, Direction.RIGHT);
  p.setConditional(1, 4, Direction.RIGHT, Direction.UP);
  p.setInstr(2, 4, Instruction.NOOP, Direction.RIGHT);
  p.setInstr(3, 4, Instruction.NOOP, Direction.RIGHT);
  p.setInstr(4, 4, Instruction.NOOP, Direction.RIGHT);
  p.setInstr(5, 4, Instruction.WRITE, Direction.UP);
  p.setInstr(5, 3, Instruction.NOOP, Direction.UP);
  
  p.setInstr(1, 3, Instruction.OVER, Direction.RIGHT);
  p.setInstr(2, 3, Instruction.OVER, Direction.RIGHT);
  p.setInstr(3, 3, Instruction.SWAP, Direction.RIGHT);
  p.setInstr(4, 3, Instruction.DIV, Direction.UP);
  p.setInstr(4, 2, Instruction.ADD, Direction.LEFT);
  p.setPushData(3, 2, 0.5, Direction.UP);
  p.setInstr(3, 1, Instruction.MUL, Direction.UP);

  return p;
}

// -------------------------------
// Setup
// -------------------------------
void setup() {
  size(1024, 768);
  
  Program program = example3();

  main.addLast(new ProgramWidget(0, 0, CELL_SIZE, program))
      .addLast(styled(new StaticTextWidget(0, program.cells_y * CELL_SIZE + 20, "R: reset, SPACE: execute next"),
                      () -> textAlign(LEFT, BOTTOM)))
      .addLast(styled(new StackTextWidget(0, program.cells_y * CELL_SIZE + 40, program),
                      () -> {fill(255, 255, 0); textAlign(LEFT, BOTTOM); }))
      .addLast(styled(new InputTextWidget(0, program.cells_y * CELL_SIZE + 60, program),
                      () -> { fill(255, 0, 255); textAlign(LEFT, BOTTOM); }))
      .addLast(styled(new OutputTextWidget(0, program.cells_y * CELL_SIZE + 80, program),
                      () -> { fill(255, 0, 255); textAlign(LEFT, BOTTOM); }))
      .addLast(styled(new ErrorMessagetWidget(0, program.cells_y * CELL_SIZE + 100, program),
                      () -> { fill(255, 0, 0); textAlign(LEFT, BOTTOM); }));
}

// -------------------------------
// Draw
// -------------------------------
void draw() {
  main.update();

  background(255, 255, 255);
  clear();
  
  main.draw();
}

void keyPressed() {
  main.keyPressed();
}

void mouseClicked() {
  main.mouseClicked();
}
