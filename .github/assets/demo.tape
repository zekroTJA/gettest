Set FontSize 30
Set Padding 30
Set WindowBar Colorful
Set TypingSpeed 70ms

Require fzf
Require gettest

Output demo.gif

Env GETTEST_EDITOR "/usr/bin/vim"
Env GETTEST_DIR "./data"


Type "gettest go"
Enter
Sleep 500ms

Escape
Type "[B"
Escape
Type "[B"
Escape
Type "[B"
Enter
Escape
Type "[Bo"
Enter
Up
Type 'import "fmt"'
Escape
Type "[B"
Escape
Type "[B"
Escape
Type "[B  "
Type 'fmt.Println("Hello world!")'
Escape
Sleep 250ms
Type ":w"
Enter
Sleep 1s

Type ":silent cd %:h"
Enter
Type ":!go run main.go"
Enter
Wait+Screen /Hello world!/
Sleep 1s

Enter
Type ":q"
Enter
Sleep 1.5s

Type "Hello World"
Sleep 500ms
Enter
Sleep 1s

Type "gettest"
Enter
Sleep 1.5s
Type "Hello world"
Sleep 1s
Enter
Sleep 1s

Escape
Type "[B"
Escape
Type "[B"
Escape
Type "[B"
Escape
Type "[B"
Enter
Sleep 1s
Type ":q!"
Enter
Sleep 1s
