
enum Instruction {
  // 0 directions (terminal)
  EMPTY, // no instruction (default). terminate in error.
  HALT, // terminates the program normally.
  
  // 1 direction (operation)
  READ, // read value from input and push to stack
  WRITE, // pop values from stack and write to output.
  DUP, // push a copy of the top of the stack.
  DROP, // pop and ignore
  EQ, // pop two values and push 1 if equal or 0 if not
  NE, // same for !=
  LT, // same for <
  LE, // same for <=
  GT, // same for >
  GE, // same for >=
  ABS, // pop and push the absolute
  ADD, // pop two numbers and push their sum
  SUB, // same for subtraction
  MUL, // same for product
  DIV, // same for division
  MOD, // same for modulus
  NOOP, // does nothing
  PUSH, // push a value to the stack
  EOF, // if the input has reached the end push 1 else 0
  OVER, // push the value just below the top of the stack
  SWAP, // swap the top 2 values in the stack
  
  // 2 directions (conditionals)
  IF // pop from stack: if not zero continue to normal direction, else to alternative direction
}

// Enumeration of the 4 directions the execution can continue
// from every instruction in the grid.
enum Direction {
  UP,
  RIGHT,
  DOWN,
  LEFT
}

// Maps a direction enum to a gradian rotation.
float rotation(Direction d) {
  switch (d) {
    case UP:
     return -PI/2;
    case RIGHT:
      return 0;
    case DOWN:
      return PI/2;
    case LEFT:
      return -PI;
    default:
     return -1;
  }
}

// Maps a direction to the next direction clockwise.
Direction nextClockwise(Direction d) {
  switch (d) {
    case UP:
     return Direction.RIGHT;
    case RIGHT:
      return Direction.DOWN;
    case DOWN:
      return Direction.LEFT;
    case LEFT:
      return Direction.UP;
    default:
     return null;
  }
}

// Enumeration of all possible kinds of instruction w.r.t execution direction.
enum DirectionMode {
  SINK, // e.g. HALT
  SINGLE, // e.g. PUSH, ADD, LE, etc.
  SPLIT // e.g. IF
}

// Maps an instruction to its direction mode.
DirectionMode directionMode(Instruction i) {
  switch (i) {
    case HALT:
    case EMPTY:
      return DirectionMode.SINK;
    case IF:
      return DirectionMode.SPLIT;
    default:
      return DirectionMode.SINGLE;
  }
}

// Enumeration of possible states the program is in.
enum ProgramState {
  READY,
  RUNNING,
  TERMINATED,
  ERROR
}

// 2D Forth virtual machine.
class Program {
  // fixed parameters
  final int columns, rows; // number of cols and rows
  final int originRow, originCol; // start of the execution
  
  // program data
  final Instruction[][] grid;  // instruction ops
  final Direction[][] direction_1; // normal direction flow
  final Direction[][] direction_2; // alternative direction flow
  final float[][] push_data; // data to be pushed (only PUSH instruction)
  
  // program state
  int executingRow, executingCol; // current execution
  int inputCursor; // current input position
  ProgramState state; // state of the program.
  String errorMessage; // error message, if state is ERROR
  
  final ArrayList<Float> stack = new ArrayList<>();
  final ArrayList<Float> input = new ArrayList<>();
  final ArrayList<Float> output = new ArrayList<>();
  
  // Create and initialize an empty program grid.
  Program(int columns, int rows, int originRow, int originCol) {
    this.columns = columns;
    this.rows = rows;
    this.originRow = originRow;
    this.originCol = originCol;

    grid = new Instruction[columns][];
    direction_1 = new Direction[columns][];
    direction_2 = new Direction[columns][];
    push_data = new float[columns][];
    for (int i=0; i < columns; ++i) {
      grid[i] = new Instruction[rows];
      direction_1[i] = new Direction[rows];
      direction_2[i] = new Direction[rows];
      push_data[i] = new float[rows];
      for (int j=0; j < rows; ++j) {
        grid[i][j] = Instruction.EMPTY;
        direction_1[i][j] = Direction.UP;
        direction_2[i][j] = Direction.DOWN;
        push_data[i][j] = 0;
      }
    }
    
    reset();
  }
  
  void reset() {
    executingRow = this.originRow;
    executingCol = this.originCol;
    state = ProgramState.READY;
    inputCursor = 0;
    stack.clear();
    output.clear();
    errorMessage = "";
  }
  
  void clear() {
    for (int i=0; i < columns; ++i) {
      for (int j=0; j < rows; ++j) {
        grid[i][j] = Instruction.EMPTY;
      }
    }
  }
  
  void setInput(float[] data) {
    for (float datum : data) {
      input.add(datum);
    }
  }
  
  Program setPush(int i, int j, float data, Direction d1) {
    grid[i][j] = Instruction.PUSH;
    push_data[i][j] = data;
    direction_1[i][j] = d1;
    return this;
  }
  
  Program setInst(int i, int y, Instruction instr, Direction d1) {
    grid[i][y] = instr;
    direction_1[i][y] = d1;
    return this;
  }
  
  Program setInst(int i, int y, Instruction instr) {
    grid[i][y] = instr;
    return this;
  }
  
  Program setCond(int i, int y, Direction d1, Direction d2) {
    grid[i][y] = Instruction.IF;
    direction_1[i][y] = d1;
    direction_2[i][y] = d2;
    return this;
  }

  void raiseError(String message) {
    state = ProgramState.ERROR;
    errorMessage = message;
  }
  
  boolean checkMinStack(int min) {
    if (stack.size() < min) {
      raiseError("empty stack");
      return false;
    }
    return true;
  }
  
  float popStack() {
    return stack.remove(stack.size() - 1);
  }
  
  // Execute one step. Returns true if
  // program is still running.
  boolean step() {
    if (state == ProgramState.READY) {
      state = ProgramState.RUNNING;
      return true;
    }
    
    if (state != ProgramState.RUNNING) {
      raiseError("Please reset program");
      return false;
    }
    
    // things the instruction can modify:
    Direction next = direction_1[executingRow][executingCol];
    float a, b;
    
    // case analysis on instruction:
    switch (grid[executingRow][executingCol]) {
      case EMPTY:
        raiseError("no instruction");
        return false;
      case HALT:
        state = ProgramState.TERMINATED;
        return false;
      case READ:
        if (inputCursor >= input.size()) {
          raiseError("end of input");
          return false;
        }
        stack.add(input.get(inputCursor++));
        break;
      case WRITE:
        if (!checkMinStack(1)) return false;
        output.add(popStack());
        break;
      case DUP:
        if (!checkMinStack(1)) return false;
        stack.add(stack.get(stack.size() - 1));
        break;
      case OVER:
        if (!checkMinStack(2)) return false;
        stack.add(stack.get(stack.size() - 2));
        break;
      case SWAP:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a);
        stack.add(b);
        break;
      case DROP:
        if (!checkMinStack(1)) return false;
        popStack();
        break;
      case EQ:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a == b? 1.0 : 0.0);
        break;
      case NE:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a != b? 1.0 : 0.0);        
        break;
      case LT:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a < b? 1.0 : 0.0);
        break;
      case LE:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a <= b? 1.0 : 0.0);
        break;
      case GT:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a > b? 1.0 : 0.0);
        break;
      case GE:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a >= b? 1.0 : 0.0);
        break;
      case ADD:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a + b);
        break;
      case SUB:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a - b);
        break;
      case MUL:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a * b);
        break;
      case DIV:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a / b);
        break;
      case MOD:
        if (!checkMinStack(2)) return false;
        a = popStack();
        b = popStack();
        stack.add(a % b);
        break;
      case ABS:
        if (!checkMinStack(1)) return false;
        stack.add(abs(popStack()));
        break;
      case NOOP:
        break;
      case PUSH:
        stack.add(push_data[executingRow][executingCol]);
        break;
      case EOF:
        stack.add(inputCursor >= input.size()? 1.0 : 0.0);
        break;
      case IF:
        if (!checkMinStack(1)) return false;
        a = popStack();
        if (a == 0.0) {
          next = direction_2[executingRow][executingCol];
        }
        break;
    }
    
    switch (next) {
      case LEFT:
        if (executingRow == 0) {
          raiseError("program fell out of bounds");
          return false;
        }
        --executingRow;
        break;
      case RIGHT:
        if (executingRow == columns-1) {
          raiseError("program fell out of bounds");
          return false;
        }
        ++executingRow;
        break;
      case UP:
        if (executingCol == 0) {
          raiseError("program fell out of bounds");
          return false;
        }
        --executingCol;
        break;
      case DOWN:
        if (executingCol == rows-1) {
          raiseError("program fell out of bounds");
          return false;
        }
        ++executingCol;
        break;
    }
    
    return true;
  }

}
