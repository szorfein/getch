# Contributing

If you discover issues, have ideas for improvements or new features,
please report them to the [issue tracker][1] of the repository or
submit a pull request. Please, try to follow these guidelines when you
do so.

## Issue reporting

* Check that the issue has not already been reported.
* Check that the issue has not already been fixed in the latest code (a.k.a. `master`).
* Be clear, concise and precise in your description of the problem.
* Open an issue with a descriptive title and a summary in grammatically correct, complete sentences.

## Pull requests

* Fork the project.
* Use the same coding conventions as the rest of the project.
* Commit and push until you are happy with your contribution.
* Open a [pull request][2] that relates to *only* one subject with a clear title and description in grammatically correct, complete sentences.

## Project layout

* `bin/getch` runs the installation phases exposed by `Getch::Main` in `lib/getch.rb`.
* `lib/getch/assembly.rb` orchestrates resumable steps; `lib/getch/states.rb`
  persists their completion in `/tmp/install_gentoo.yaml`. A step is saved only
  after its work completes.
* `lib/getch/tree.rb` selects the OS and filesystem implementations from the
  CLI options. OS-specific steps live in `lib/getch/gentoo/` and
  `lib/getch/void/`; filesystem-specific steps live in
  `lib/getch/filesystem/`.
* Shared system utilities live under `lib/`, and configuration routines live
  in `lib/getch/config/`.

Run the unit tests with `rake test`. The assembly tests use substitutes for
installer components and do not partition or format disks.

## For More Hardware Support

* Include the output of `lspci`:
* Include the output of `cat /proc/modules`:

```
$ cat /proc/modules
snd_hda_codec_via 16384 0 - Live 0x0000000000000000
snd_hda_codec_generic 65536 1 snd_hda_codec_via, Live 0x0000000000000000
snd_hda_codec_hdmi 49152 0 - Live 0x0000000000000000
...
```

[1]: https://github.com/szorfein/getch/issues
[2]: https://help.github.com/articles/about-pull-requests

