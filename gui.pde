
abstract class Widget {
  private float x;
  private float y;
  WidgetContainer parent = null;
  
  Widget(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  void transform() {
    translate(x, y);
  }
  
  void destroy() {
    if (parent != null) {
      parent.remove(this);
    }
  }
 
  final float absoluteX() {
    if (parent != null) {
      return parent.absoluteX() + x;
    } else {
      return x;
    }
  }
  
  final float absoluteY() {
    if (parent != null) {
      return parent.absoluteY() + y;
    } else {
      return y;
    }
  }
  
  final float mouseX() {
    return mouseX - absoluteX();
  }
  
  final float mouseY() {
    return mouseY - absoluteY();
  }
  
  abstract void draw();

  void update() {};
  boolean keyPressed() { return false; }
  boolean mouseClicked() { return false; }
}

class WidgetContainer extends Widget {
  private ArrayList<Widget> widgets = new ArrayList<>();
  private ArrayList<Widget> toAddFirst = new ArrayList<>();
  private ArrayList<Widget> toAddLast = new ArrayList<>();
  private ArrayList<Widget> toRemove = new ArrayList<>();
  
  WidgetContainer(float x, float y) {
    super(x, y);
  }
  
  void draw() {
    pushMatrix();
    transform();
    for (Widget widget : widgets) {
      widget.draw();
    }
    popMatrix();
  }
  
  void update() {
    for (Widget widget : widgets) {
      widget.update();
    }
    
    for (Widget widget : toRemove) {
      assert(widgets.remove(widget));
    }
    toRemove.clear();
    
    for (Widget widget : toAddFirst) {
      widgets.add(0, widget);
    }
    toAddFirst.clear();
    
    for (Widget widget : toAddLast) {
      widgets.add(widget);
    }
    toAddLast.clear();
  }
  
  boolean keyPressed() {
    for (int i=widgets.size()-1; i >=0; --i) {
      if (widgets.get(i).keyPressed()) {
        return true;
      }
    }
    return false;
  }
  
  boolean mouseClicked() {
    for (int i=widgets.size()-1; i >=0; --i) {
      if (widgets.get(i).mouseClicked()) {
        return true;
      }
    }
    return false;
  }
  
  final WidgetContainer addFirst(Widget widget) {
    widget.parent = this;
    toAddFirst.add(widget);
    return this;
  }
  
  final WidgetContainer addLast(Widget widget) {
    widget.parent = this;
    toAddLast.add(widget);
    return this;
  }   
  
  final WidgetContainer remove(Widget widget) {
    widget.parent = null;
    toRemove.add(widget);
    return this;
  }
}

class Styled extends WidgetContainer {
  private final Runnable setStyle;
  
  Styled(Widget widget, Runnable setStyle) {
    super(0, 0);
    addLast(widget);
    this.setStyle = setStyle;
  }
  
  void draw() {
    setStyle.run();
    super.draw();
  }
}

Widget styled(Widget widget, Runnable setStyle) {
  return new Styled(widget, setStyle);
}

interface InputListener {
  void completed(String text);
  void cancelled();
}

class InputDialog extends Widget {
  String result = "";
  final String prompt;
  final InputListener listener;
  
  InputDialog(float x, float y, String prompt, InputListener listener) {
    super(x, y);
    this.prompt = prompt;
    this.listener = listener;
  }
  
  void draw() {
    String cursor;
    if (millis() % 200 > 100) {
      cursor = "|";
    } else {
      cursor = " ";
    }
    
    pushMatrix();
    transform();
    text(prompt + result + cursor, 0, 0);
    popMatrix();
  }
  
  boolean keyPressed() {
    if (keyCode == ENTER) {
      if (listener != null) listener.completed(result);
      destroy();
    } else if (keyCode == BACKSPACE) {
      if (result.length() > 0) {
        result = result.substring(0, result.length() - 1);
      }
    } else {
      result += key;
    }
    return true;
  }
  
  boolean mouseClicked() {
   final float width = textWidth(prompt + result + "|");
   final float mX = mouseX();
   final float mY = mouseY();
   if (mX < 0 || mX > width || mY < 0 || mY > 50) {
     if (listener != null) listener.cancelled();
     destroy();
   }
   return true;
  }
}

abstract class DynamicTextWidget extends Widget {
  
  DynamicTextWidget(float x, float y) {
    super(x, y);
  }
  
  abstract String getText();
  
  void draw() {
    pushMatrix();
    transform();
    text(getText(), 0, 0);
    popMatrix();
  }
}

class StaticTextWidget extends DynamicTextWidget {
  
  private final String text;
  
  StaticTextWidget(float x, float y, String text) {
    super(x, y);
    this.text = text;
  }
  
  String getText() { return text; }
}
