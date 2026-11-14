namespace ProjectIGI.Input;

/// <summary>A control on a game controller that can be bound to an action: the fourteen buttons plus the two triggers.</summary>
/// <remarks>
/// Values <c>0..13</c> match <see cref="GamepadButton"/> exactly, so a button control converts with a
/// cast; the triggers follow, since they are axes rather than buttons and need a threshold to read as
/// pressed. <see cref="None"/> is the unbound row: a default whose control was already taken arrives
/// unbound rather than driving two actions behind the player's back.
/// </remarks>
public enum GamepadControl
{
    /// <summary>The bottom face button — A / ✕.</summary>
    South = 0,

    /// <summary>The right face button — B / ○.</summary>
    East = 1,

    /// <summary>The left face button — X / □.</summary>
    West = 2,

    /// <summary>The top face button — Y / △.</summary>
    North = 3,

    /// <summary>The left shoulder bumper.</summary>
    LeftShoulder = 4,

    /// <summary>The right shoulder bumper.</summary>
    RightShoulder = 5,

    /// <summary>The left stick pressed in.</summary>
    LeftStick = 6,

    /// <summary>The right stick pressed in.</summary>
    RightStick = 7,

    /// <summary>The start / menu button.</summary>
    Start = 8,

    /// <summary>The back / view / select button.</summary>
    Back = 9,

    /// <summary>The directional pad up.</summary>
    DpadUp = 10,

    /// <summary>The directional pad down.</summary>
    DpadDown = 11,

    /// <summary>The directional pad left.</summary>
    DpadLeft = 12,

    /// <summary>The directional pad right.</summary>
    DpadRight = 13,

    /// <summary>The left trigger, read as pressed past the trigger threshold.</summary>
    LeftTrigger = 14,

    /// <summary>The right trigger, read as pressed past the trigger threshold.</summary>
    RightTrigger = 15,

    /// <summary>No control: the action cannot fire from the controller.</summary>
    None = 16,
}

/// <summary>Converts controller controls to their save-file symbols and player-facing names and back.</summary>
public static class GamepadControlNames
{
    /// <summary>Every control a binding row can capture, buttons first so a simultaneous press binds the button.</summary>
    public static IReadOnlyList<GamepadControl> AllBindable { get; } =
    [
        GamepadControl.South,
        GamepadControl.East,
        GamepadControl.West,
        GamepadControl.North,
        GamepadControl.LeftShoulder,
        GamepadControl.RightShoulder,
        GamepadControl.LeftStick,
        GamepadControl.RightStick,
        GamepadControl.Start,
        GamepadControl.Back,
        GamepadControl.DpadUp,
        GamepadControl.DpadDown,
        GamepadControl.DpadLeft,
        GamepadControl.DpadRight,
        GamepadControl.LeftTrigger,
        GamepadControl.RightTrigger,
    ];

    /// <summary>Determines whether a control is one of the two triggers rather than a button.</summary>
    /// <param name="control">The control.</param>
    /// <returns><see langword="true"/> for the triggers.</returns>
    public static bool IsTrigger(GamepadControl control) =>
        control is GamepadControl.LeftTrigger or GamepadControl.RightTrigger;

    /// <summary>Converts a button control to its button, or <see langword="null"/> for a trigger or no control.</summary>
    /// <param name="control">The control.</param>
    /// <returns>The button, or <see langword="null"/>.</returns>
    public static GamepadButton? ToButton(GamepadControl control) =>
        control >= GamepadControl.South && control <= GamepadControl.DpadRight
            ? (GamepadButton)control
            : null;

    /// <summary>Converts a control to the symbol the save file stores it under.</summary>
    /// <param name="control">The control.</param>
    /// <returns>The symbol, such as <c>PAD_SOUTH</c>.</returns>
    public static string ToSymbol(GamepadControl control) => control switch
    {
        GamepadControl.South => "PAD_SOUTH",
        GamepadControl.East => "PAD_EAST",
        GamepadControl.West => "PAD_WEST",
        GamepadControl.North => "PAD_NORTH",
        GamepadControl.LeftShoulder => "PAD_LEFT_SHOULDER",
        GamepadControl.RightShoulder => "PAD_RIGHT_SHOULDER",
        GamepadControl.LeftStick => "PAD_LEFT_STICK",
        GamepadControl.RightStick => "PAD_RIGHT_STICK",
        GamepadControl.Start => "PAD_START",
        GamepadControl.Back => "PAD_BACK",
        GamepadControl.DpadUp => "PAD_DPAD_UP",
        GamepadControl.DpadDown => "PAD_DPAD_DOWN",
        GamepadControl.DpadLeft => "PAD_DPAD_LEFT",
        GamepadControl.DpadRight => "PAD_DPAD_RIGHT",
        GamepadControl.LeftTrigger => "PAD_LEFT_TRIGGER",
        GamepadControl.RightTrigger => "PAD_RIGHT_TRIGGER",
        _ => "PAD_NONE",
    };

    /// <summary>Parses a save-file symbol back into a control.</summary>
    /// <param name="symbol">The symbol.</param>
    /// <param name="control">Receives the control.</param>
    /// <returns><see langword="false"/> when the symbol names no control, so the row is dropped rather than misbound.</returns>
    public static bool TryParseSymbol(string symbol, out GamepadControl control)
    {
        GamepadControl? parsed = symbol switch
        {
            "PAD_SOUTH" => GamepadControl.South,
            "PAD_EAST" => GamepadControl.East,
            "PAD_WEST" => GamepadControl.West,
            "PAD_NORTH" => GamepadControl.North,
            "PAD_LEFT_SHOULDER" => GamepadControl.LeftShoulder,
            "PAD_RIGHT_SHOULDER" => GamepadControl.RightShoulder,
            "PAD_LEFT_STICK" => GamepadControl.LeftStick,
            "PAD_RIGHT_STICK" => GamepadControl.RightStick,
            "PAD_START" => GamepadControl.Start,
            "PAD_BACK" => GamepadControl.Back,
            "PAD_DPAD_UP" => GamepadControl.DpadUp,
            "PAD_DPAD_DOWN" => GamepadControl.DpadDown,
            "PAD_DPAD_LEFT" => GamepadControl.DpadLeft,
            "PAD_DPAD_RIGHT" => GamepadControl.DpadRight,
            "PAD_LEFT_TRIGGER" => GamepadControl.LeftTrigger,
            "PAD_RIGHT_TRIGGER" => GamepadControl.RightTrigger,
            "PAD_NONE" => GamepadControl.None,
            _ => null,
        };

        control = parsed ?? GamepadControl.None;
        return parsed is not null;
    }

    /// <summary>The name the player reads on a binding row.</summary>
    /// <param name="control">The control.</param>
    /// <returns>The short pad label: the letter, bumper or trigger name.</returns>
    public static string DisplayName(GamepadControl control) => control switch
    {
        GamepadControl.South => "A",
        GamepadControl.East => "B",
        GamepadControl.West => "X",
        GamepadControl.North => "Y",
        GamepadControl.LeftShoulder => "LB",
        GamepadControl.RightShoulder => "RB",
        GamepadControl.LeftStick => "L3",
        GamepadControl.RightStick => "R3",
        GamepadControl.Start => "Start",
        GamepadControl.Back => "Select",
        GamepadControl.DpadUp => "D-Pad Up",
        GamepadControl.DpadDown => "D-Pad Down",
        GamepadControl.DpadLeft => "D-Pad Left",
        GamepadControl.DpadRight => "D-Pad Right",
        GamepadControl.LeftTrigger => "LT",
        GamepadControl.RightTrigger => "RT",
        _ => "Unbound",
    };
}
