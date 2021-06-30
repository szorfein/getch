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

