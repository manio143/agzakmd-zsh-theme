# How themes for oh-my-zsh work?
I've spent a couple of hours trying to find what works how, so now that I figured most stuff out I decided to write them down here.

First of all, where is the information about how our prompt should look like?

There are a few variables but the most important ones are `$PROMPT` for the left part and `$RPROMPT` for the right part.

When you understand the basics, it turns out that it's all rather simple.

What we're doing is just taking information from the shell and programs and displaying it with a few additional characters and colorful background.

The Z shell has a special syntax for creating control sequences used by the terminal to display different colors. You can check them out at [Prompt Expansion](http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html).

Here are a few basic ones:

* `%F{color}` - change the foreground (text) to `color`
* `%K{color}` - change the background to `color`
* `%D{dateformat}` - display date in `dateformat`, e.g. `%I:%M:%S %p` - 10:12:36 AM
* `%B` - start bold | `%b%` - stop bold
* `%~` - current path | `%3~` - current path limited to 3 levels up
* `%M` - hostname | `%m` - hostname up to the first '.'
* `%n` - username

So we're constructing a long string containing the colours and information that is then parsed and displayed on the screen.

The [Powerline](https://github.com/powerline/powerline) is used for their [fonts](https://github.com/powerline/fonts) that give us characters like , , , ⚡, ⚙.

## Colors
Colors are dependant on your terminal. The basic ones that will be supported everywhere are:

- black - 0
- red - 1
- green - 2
- yellow - 3
- blue - 4
- magenta - 5
- cyan - 6
- white - 7

But many terminals may support up to 255 in the color index.
