class Tput
  module Events
    include EventHandler

    #event EventEvent#, ...

    event MouseEvent#, key : ...
    event MouseWheelEvent#, ...
    #event MouseButtonDownEvent, buttons : MouseButton, modifiers : KeyboardModifier, point : Point
    #event MouseButtonUpEvent, buttons : MouseButton, modifiers : KeyboardModifier, point : Point
    #event MouseButtonClickEvent, buttons : MouseButton, modifiers : KeyboardModifier, point : Point
    #event MouseButtonDoubleClickEvent, buttons : MouseButton, modifiers : KeyboardModifier, point : Point
    #event MouseOutEvent#, ...
    #event MouseOverEvent#, ...

    event KeyPressEvent, key : Key
  end
end
