toggle_q := 0
toggle_shortcut := 0

; Ctrl + Shift + q で `q` の出力を切り替える
^+q::
    toggle_q := !toggle_q
    MsgBox, % toggle_q ? "`Q` OFF" : "`Q` ON"
Return

; Ctrl + Shift + Alt + q でショートカットの有効無効を切り替える
^!+q::
    toggle_shortcut := !toggle_shortcut
    MsgBox, % toggle_shortcut ? "Shortcut OFF" : "Shortcut ON"
Return

; "ltu" と "q" の切り替え
$q::
    if (toggle_q = 0) {
        Send, ltu
    } else {
        Send, q
    }
Return

; 一番右 -> Enter
^+j::
    if (toggle_shortcut = 0) {
        Send, {End}{Enter}
    }
Return

; 一番右 -> Enter -> 一番右
^+i::
    if (toggle_shortcut = 0) {
        Send, {End}{Down}{End}
    }
Return

; 変換キー（sc079）と矢印キーの割り当て
; sc079 & j::Send, {Left}
; sc079 & l::Send, {Right}
; sc079 & i::Send, {Up}
; sc079 & k::Send, {Down}

; Ctrl + 変換キー + 矢印キーの割り当て
; ^sc079 & j::Send, ^{Left}
; ^sc079 & l::Send, ^{Right}
; ^sc079 & i::Send, ^{Up}
; ^sc079 & k::Send, ^{Down}
; Return

; super god ultra shortcut
sc079 & j::
sc079 & l::
sc079 & i::
sc079 & k::
sc079 & q::
    ctrl := GetKeyState("Ctrl", "P")
    shift := GetKeyState("Shift", "P")
    if (ctrl && shift) {
        ; Ctrl+Shift+矢印
        if (A_ThisHotkey = "sc079 & j")
            Send, ^+{Left}
        else if (A_ThisHotkey = "sc079 & l")
            Send, ^+{Right}
        else if (A_ThisHotkey = "sc079 & i")
            Send, ^+{Up}
        else if (A_ThisHotkey = "sc079 & k")
            Send, ^+{Down}
    } else if (ctrl) {
        ; Ctrl+矢印
        if (A_ThisHotkey = "sc079 & j")
            Send, ^{Left}
        else if (A_ThisHotkey = "sc079 & l")
            Send, ^{Right}
        else if (A_ThisHotkey = "sc079 & i")
            Send, ^{Up}
        else if (A_ThisHotkey = "sc079 & k")
            Send, ^{Down}
    } else if (shift) {
        ; Shift+矢印
        if (A_ThisHotkey = "sc079 & j")
            Send, +{Left}
        else if (A_ThisHotkey = "sc079 & l")
            Send, +{Right}
        else if (A_ThisHotkey = "sc079 & i")
            Send, +{Up}
        else if (A_ThisHotkey = "sc079 & k")
            Send, +{Down}
    } else {
        ; 通常の矢印
        if (A_ThisHotkey = "sc079 & j")
            Send, {Left}
        else if (A_ThisHotkey = "sc079 & l")
            Send, {Right}
        else if (A_ThisHotkey = "sc079 & i")
            Send, {Up}
        else if (A_ThisHotkey = "sc079 & k")
            Send, {Down}
        else if (A_ThisHotkey = "sc079 & q")
            Send, q
    }
return
