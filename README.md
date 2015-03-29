DockWin - Lightweight Docking Windows for Emacs
===============================================

![](screencast.gif?raw=true)

DockWin provides four expandable side docking windows for your Emacs frame, one on each side of the
frame (top, bottom, left, right). The docking windows have three states: closed, inactive, and
active. They automatically expand when activated and collapse when inactive. Each window can be
configured to host only certain selected buffers (e.g. use the bottom window for shells and compile
windows, top for help windows and side for undo tree).

The goal of DockWin is to provide the docking window functionality which can be found integrated
into larger packages (e.g. EDE) in a lightweight independent package. Also, DockWin will not destroy
any of your non-docking windows (e.g. in order to re-create the layout) which might be important for
other packages.


Basic Usage
-----------

Whenever a new dockable buffer is displayed, a docking window will be created. If you choose to
automatically activate the window (see Configuration), it will also be expanded and the focus will
be placed in the window. The commands `dockwin-toggle-<position>-window` can be used to activate and
deactivate a specific window. It's good to have a convenient binding for that (see Key Bindings).

The command `dockwin-go-to-previous-window` can be used globally to always go to the previous active
non-docking window. I prefer that over the standard `other-window`, especially when coupled with
[Windmove](http://www.gnu.org/software/emacs/manual/html_node/emacs/Window-Convenience.html).

When a docking window is activated, the command `dockwin-switch-to-buffer` is locally bound to a
key, which by default is `C-x C-b`, and thus replaces the standard buffer list key. This command
lists all the buffers that match the current docking window using IDO and allows for convenient
switching between relevant buffers in a docking window. The buffers are listed in the order that
they were current; the buffers that were current most recently come first.

When enabled, the modeline will display all buffers relevant for the docking window, sorted
alphabetically. It is then possible to move to the previous/next buffer in alphabetical order using
`dockwin-previous-buffer`/`dockwin-next-buffer`, by default bound to `C-x <left>`/`C-x <right>`.

You can control what happens after killing a buffer or quitting a window (using `quit-window`). In
such case, the docking window can remain active (displaying a different buffer), become inactive or
completely closed (hidden). It is also possible to configure certain buffers to always be killed
when quitting the window. `C-x C-g` bound to `dockwin-close-window` can be used to close the window
without killing/quitting any buffers.


Installation
------------

I highly recommend installing DockWin through elpa (it's available on melpa).

```
M-x package-install dockwin
```

Then, add the following line to your init file:

```
(require 'multiple-cursors)
```


Configuration - Key Bindings
----------------------------

DockWin does not perform any global keyboard setup, but it's easy to configure the relevant key bindings.

If you plan to use all four windows and are not really using the default Fx bindings, this might work:

```
(global-set-key (kbd "<f1>") 'dockwin-toggle-left-window)
(global-set-key (kbd "<f2>") 'dockwin-toggle-top-window)
(global-set-key (kbd "<f3>") 'dockwin-toggle-bottom-window)
(global-set-key (kbd "<f4>") 'dockwin-toggle-right-window)
```

If you need only one or two windows, this might work for you:

```
(global-set-key (kbd "C-`") 'dockwin-toggle-bottom-window)
(global-set-key (kbd "C-~") 'dockwin-toggle-right-window)
```

It might also be convenient to specialize those bindings for particular major modes in order to
always go to the most relevant buffer first. For example, to always start/go to Python shell in
python-mode, use this:

```
(add-hook 'python-mode-hook
          (lambda ()
            (define-key python-mode-map (kbd "C-'")
              (lambda ()
                (interactive)
                (call-interactively 'run-python)
                (display-buffer "*Python*")))) t)
```

The `dockwin-go-to-previous-window` command is handy as well to jump between two frequently used
non-docking windows, you can bind it globally e.g. over the standard `other-window`:

```
(global-set-key (kbd "C-x o") 'dockwin-dockwin-go-to-previous-window)
```

Finally, if you would like to customize the local key bindings used inside the docked buffers,
modify the `dockwin-buffer-mode-map`, e.g.:

```
(define-key dockwin-buffer-mode-map (kbd "C-x C-b") nil)
(define-key dockwin-buffer-mode-map (kbd "<new_key>") 'dockwin-switch-to-buffer)
```


Configuration - DockWin
-----------------------

Now, you can configure DocWin using customize:

```
M-x customzie-group dockwin
```

or by changing the following variables in your init file:

- `dockwin-buffer-settings` - Buffer settings. Determine which buffers should be shown in docking
  windows and how they should be displayed. The value is a list of `CONFIG` which should be of the
  form `(PATTERN . PROPERTIES)` where `PATTERN` is characterizing the buffer and `PROPERTIES` is a list
  of `KEYWORDS` and `VALUES`. `PATTERN` can be a buffer name matching regexp, or a symbol specifying
  the major-mode of the buffer. Note, that for some buffers, the major mode symbol will not work as
  the mode is set after the buffer is displayed (for those, use the regexp name instead). The first
  matching configuration is used. Available keywords:
    - `:position` - The docking window which should be used for the buffer. Possible values: `top`,
      `:bottom`, `left`, `right`.
    - `:activate` - If true, the docking window will be activated when this buffer is displayed. Note,
             that if some other Emacs code activates the window, DockWin will not prevent it even if
             this is set to nil.
    - `:kill` - If true, always kill the buffer on quit.
    - `:catch-switching` - If set to 't, `switch-to-buffer` events will be caught as well. If set to
              'f, those events will not be caught. If set to nil, default value will be used. Some
              buffers are displayed in the current window using `switch-to-buffer` rather than
              `display-buffer`, e.g. term. Using this option will allow for displaying such buffers
              in the docking windows as well. However, this will make it impossible to display the
              buffer in a non-docking window, e.g. using `C-x b`. After catching such event,
              window will always be activated.

- `dockwin-default-position` - Default docking window position for a buffer specified in the
  settings. This must be one of: `left`, `top`, `right`, or `bottom`. This value can be overridden
  by a property in `dockwin-buffer-settings`.

- `dockwin-default-kill` - If not nil, buffers in docking windows will be killed by default. This
  value can be overridden by a property in `dockwin-buffer-settings`.

- `dockwin-default-activate` - If not nil, windows will be activated by default when buffers are
  displayed. This value can be overridden by a property in `dockwin-buffer-settings`.

- `dockwin-default-catch-switching` - If not nil, `switch-to-buffer` events will be caught as well.
  Some buffers are displayed in the current window using `switch-to-buffer` rather than
  `display-buffer`, e.g. `term`. Using this option will allow for displaying such buffers in the
  docking windows as well. However, this will make it impossible to display the buffer in a
  non-docking window, e.g. using `C-x b`. After catching such event, window will always be
  activated. This value can be overridden by a property in `dockwin-buffer-settings`.

- `dockwin-bottom-height-min` - Bottom window size when inactive

- `dockwin-bottom-height-max` - Bottom window size when active

- `dockwin-top-height-min` - Top window size when inactive

- `dockwin-top-height-max` - Top window size when active

- `dockwin-left-width-min` - Left window size when inactive

- `dockwin-left-width-max` - Left window size when active

- `dockwin-right-width-min` - Right window size when inactive

- `dockwin-right-width-max` - Right window size when active

- `dockwin-add-buffers-to-modeline` - Set to nil if you want to disable the modeline buffer list for docking windows.

- `dockwin-trim-special-buffer-names` - If not nil, asterisks will be trimmed from special buffer names in mode-line.

- `dockwin-on-kill` - Determines what should be done when a buffer is killed. If set to 'close, the
window is closed. If set to 'deactivate, the window is deactivated. If set to nil, nothing happens.

- `dockwin-on-quit` - Determines what should be done when `quit-window' happens. If set to 'close,
the window is closed. If set to 'deactivate, the window is deactivated. If set to nil, nothing
happens.

- `dockwin-mode-line-separator-face` - Face used for separators on DockWin mode-line.

- `dockwin-mode-line-current-buffer-face` - Face used to display current buffer on DockWin mode-line.

- `dockwin-mode-line-other-buffer-face` - Face used to display other buffers on DockWin mode-line.



Commands
--------

- `(dockwin-go-to-previous-window)` - Go to previous non-docking window. If there is no history, go
  to other window.

- `(dockwin-switch-to-buffer (&optional position))` - Switch buffer in the window at `POSITION` to other
  valid buffer in that window. If `POSITION` is nil, and inside a docking window, use the current
  window position.

- `(dockwin-create-window (position))` - Create the docking window at `POSITION` if not yet created.
  Show the most recent buffer in the window. If there is no buffer to show, display message. Return the
  window.

- `(dockwin-create-bottom-window)` - Create the bottom docking window if not yet created. Show the
  most recent buffer in the window. If there is no buffer to show, display message.

- `(dockwin-create-top-window)` - Create the top docking window if not yet created. Show the most
  recent buffer in the window. If there is no buffer to show, display message.

- `(dockwin-create-left-window)` - Create the left docking window if not yet created. Show the most
  recent buffer in the window. If there is no buffer to show, display message.

- `(dockwin-create-right-window)` - Create the right docking window if not yet created. Show the most
  recent buffer in the window. If there is no buffer to show, display message.

- `(dockwin-activate-window (position))` - Activate the docking window at `POSITION` if it's live.
  If not, create it, activate it and show the most recent buffer. If there is no buffer to show,
  display message. Return the window.

- `(dockwin-activate-bottom-window)` - Activate the bottom docking window if it's live. If not, create
  it, activate it and show the most recent buffer. If there is no buffer to show, display message.

- `(dockwin-activate-top-window)` - Activate the top docking window if it's live. If not, create it,
  activate it and show the most recent buffer. If there is no buffer to show, display message.

- `(dockwin-activate-left-window)` - Activate the left docking window if it's live. If not, create
  it, activate it and show the most recent buffer. If there is no buffer to show, display message.

- `(dockwin-activate-right-window)` - Activate the right docking window if it's live. If not, create
  it, activate it and show the most recent buffer. If there is no buffer to show, display message.

- `(dockwin-toggle-bottom-window)` - Activate the bottom docking window if it's not active. If it is
  active, return to previous non-docking window.

- `(dockwin-toggle-top-window)` - Activate the top docking window if it's not active. If it is
  active, return to previous non-docking window.

- `(dockwin-toggle-left-window)` - Activate the left docking window if it's not active. If it is
  active, return to previous non-docking window.

- `(dockwin-toggle-right-window)` - Activate the right docking window if it's not active. If it is
  active, return to previous non-docking window.

- `(dockwin-close-window (&optional position frame))` - Close the docking window at POSITION in
  FRAME if it's live. If not, do nothing. If POSITION is nil, try to close the currently selected
  window. FRAME defaults to current frame

- `(dockwin-close-top-window ())` - Close the top docking window if it's live. If not, do nothing.

- `(dockwin-close-bottom-window ())` - Close the bottom docking window if it's live. If not, do
  nothing.

- `(dockwin-close-left-window ())` - Close the left docking window if it's live. If not, do nothing.

- `(dockwin-close-right-window ())` - Close the right docking window if it's live. If not, do
  nothing.

- `(dockwin-kill-buffer (&optional position))` - Kill the current buffer in window at `POSITION`. Show
  the next valid buffer in the window instead. If `POSITION` is nil, use the currently selected window.

- `dockwin-next-buffer (&optional position)` - Display the next buffer in docking window at
  `POSITION`. The next buffer is the next one in the alphabetical order. Position must be one of: top,
  bottom, left, right.

- `dockwin-previous-buffer (&optional position)` - Display the previous buffer in docking window at
  `POSITION`. The previous buffer is the previous one in the alphabetical order. Position must be one
  of: top, bottom, left, right.
