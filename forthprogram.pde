
enum Instruction {
  // 0 directions (sink)
  EMPTY, // default
  HALT,
  
  // 1 direction (operation)
  READ,
  WRITE,
  DUP,
  DROP,
  EQ,
  NE,
  LT,
  LE,
  GT,
  GE,
  ABS,
  ADD,
  SUB,
  MUL,
  DIV,
  MOD,
  NOOP,
  PUSH,
  EOF,
  OVER,
  SWAP,
  
  // 2 directions (conditionals)
  IF
}

enum Direction {
  UP,
  RIGHT,
  DOWN,
  LEFT
}

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

enum DirectionMode {
  SINK, // e.g. HALT
  SINGLE, // e.g. PUSH, ADD, LE, etc.
  SPLIT // e.g. IF
}

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

enum ProgramState {
  READY,
  RUNNING,
  TERMINATED,
  ERROR
}

class Program {
  // fixed parameters
  final int cells_x, cells_y;
  final int origin_x, origin_y;
  
  // program data
  final Instruction[][] grid;
  final Direction[][] direction_1;
  final Direction[][] direction_2;
  final float[][] push_data;
  
  // program state
  int current_x, current_y;
  int input_cursor;
  ProgramState state;
  String error_message;
  
  final ArrayList<Float> stack = new ArrayList<>();
  final ArrayList<Float> input = new ArrayList<>();
  final ArrayList<Float> output = new ArrayList<>();
  
  // Create and initialize an empty program grid.
  Program(int cells_x, int cells_y, int origin_x, int origin_y) {
    this.cells_x = cells_x;
    this.cells_y = cells_y;
    this.origin_x = origin_x;
    this.origin_y = origin_y;

    grid = new Instruction[cells_x][];
    direction_1 = new Direction[cells_x][];
    direction_2 = new Direction[cells_x][];
    push_data = new float[cells_x][];
    for (int i=0; i < cells_x; ++i) {
      grid[i] = new Instruction[cells_y];
      direction_1[i] = new Direction[cells_y];
      direction_2[i] = new Direction[cells_y];
      push_data[i] = new float[cells_y];
      for (int j=0; j < cells_y; ++j) {
        grid[i][j] = Instruction.EMPTY;
        direction_1[i][j] = Direction.UP;
        direction_2[i][j] = Direction.DOWN;
        push_data[i][j] = 0;
      }
    }
    
    reset();
  }
  
  void reset() {
    current_x = this.origin_x;
    current_y = this.origin_y;
    state = ProgramState.READY;
    input_cursor = 0;
    stack.clear();
    output.clear();
    error_message = "";
  }
  
  void setInput(float[] data) {
    for (float datum : data) {
      input.add(datum);
    }
  }
  
  void setPushData(int x, int y, float data, Direction d1) {
    grid[x][y] = Instruction.PUSH;
    push_data[x][y] = data;
    direction_1[x][y] = d1;
  }
  
  void setInstr(int x, int y, Instruction instr, Direction d1) {
    grid[x][y] = instr;
    direction_1[x][y] = d1;
  }
  
  void setInstr(int x, int y, Instruction instr) {
    grid[x][y] = instr;
  }
  
  void setConditional(int x, int y, Direction d1, Direction d2) {
    grid[x][y] = Instruction.IF;
    direction_1[x][y] = d1;
    direction_2[x][y] = d2;
  }

  void raiseError(String message) {
    state = ProgramState.ERROR;
    error_message = message;
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
    Direction next = direction_1[current_x][current_y];
    float a, b;
    
    // case analysis on instruction:
    switch (grid[current_x][current_y]) {
      case EMPTY:
        raiseError("no instruction");
        return false;
      case HALT:
        state = ProgramState.TERMINATED;
        return false;
      case READ:
        if (input_cursor >= input.size()) {
          raiseError("end of input");
          return false;
        }
        stack.add(input.get(input_cursor++));
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
        stack.add(push_data[current_x][current_y]);
        break;
      case EOF:
        stack.add(input_cursor >= input.size()? 1.0 : 0.0);
        break;
      case IF:
        if (!checkMinStack(1)) return false;
        a = popStack();
        if (a == 0.0) {
          next = direction_2[current_x][current_y];
        }
        break;
    }
    
    switch (next) {
      case LEFT:
        if (current_x == 0) {
          raiseError("program fell out of bounds");
          return false;
        }
        --current_x;
        break;
      case RIGHT:
        if (current_x == cells_x-1) {
          raiseError("program fell out of bounds");
          return false;
        }
        ++current_x;
        break;
      case UP:
        if (current_y == 0) {
          raiseError("program fell out of bounds");
          return false;
        }
        --current_y;
        break;
      case DOWN:
        if (current_y == cells_y-1) {
          raiseError("program fell out of bounds");
          return false;
        }
        ++current_y;
        break;
    }
    
    return true;
  }

}
