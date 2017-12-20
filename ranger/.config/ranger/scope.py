#!/usr/bin/env python3

import io
import itertools
import pathlib
import shutil
import subprocess
import sys

MAX_LINES = 200

def run_trim(cmd, ret_code):
    with io.BytesIO() as ret:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
        with proc:
            # it's safe to iterate over stdout directly,
            # because stdin/stderr are inherited and will
            # not deadlock (stdin is closed by ranger)
            for idx, line in enumerate(proc.stdout):
                # the process might get stuck if nobody's
                # consuming its stdout
                # so we continue reading lines after the
                # maximum, and just throw them away
                if idx < MAX_LINES:
                    ret.write(line)
        if proc.returncode == 0:
            ret.seek(0)
            shutil.copyfileobj(ret, sys.stdout.buffer)
            sys.exit(ret_code)

# display stdout as preview
EXIT_STDOUT = 0
# don't display a preview
EXIT_NOPREVIEW = 1
# display the file's raw content as preview
EXIT_RAW = 2
# display stdout as preview
# don't reload if preview window changes width
EXIT_FIXWIDTH = 3
# display stdout as preview
# don't reload if preview window changes height
EXIT_FIXHEIGHT = 4
# display stdout as preview
# don't reload if preview window changes size
EXIT_FIXBOTH = 5
# display the file at CACHE as image preview
EXIT_IMAGECACHED = 6
# display the file's raw content as image preview
EXIT_IMAGERAW = 7

PATH = pathlib.Path(sys.argv[1])
WIDTH = int(sys.argv[2])
HEIGHT = int(sys.argv[3])
CACHE = pathlib.Path(sys.argv[4])

EXTENSIONS = list(map(lambda ext: ext.lstrip('.'), PATH.suffixes))
# TODO: https://github.com/ahupp/python-magic
# TODO: granular parsing of mime type
MIME = subprocess.run(
    ['file', '--mime-type', '--dereference', '--brief', '--', PATH],
    stdout=subprocess.PIPE,
    check=True
).stdout.strip()

if MIME.startswith(b'text/') or MIME.endswith(b'/xml'):
    sys.exit(2)

# various extensions that atool recognizes
ARCHIVE_EXT = {
    # tar
    'tar',
    # gzip
    'gz', 'tgz',
    # bzip
    'bz', 'tbz',
    # bzip2
    'bz2', 'tbz2',
    # lzip
    'lz', 'tlz',
    # lzop
    'lzo', 'tzo',
    # xz
    'xz', 'txz', 'lzma', 'tlzma',
    # unzip
    'zip',
    # unrar
    'rar',
    # lhasa
    'lha', 'lzh',
    # unace
    'ace',
    # arj
    'arj',
    # rpm
    'rpm',
    # deb
    'deb',
    # cab
    'cab',
    # cpio
    'cpio',
    # arc
    'arc',
    # p7zip
    '7z', 't7z',
    # uncompress
    'z', 'tz',
    # java
    'jar', 'war',
    # ar
    'a',
    # unalz
    'alz',
    # rzip
    'rz',
    # lrzip
    'lrz',
}
ARCHIVE_MIME = {
    b'application/x-tar',
    b'application/x-bzip',
    b'application/x-bzip2',
    b'application/zip',
    b'application/x-rar',
    b'application/x-7z-compressed',
    b'application/java-archive',
}
if (EXTENSIONS and EXTENSIONS[-1].lower() in ARCHIVE_EXT) or (MIME in ARCHIVE_MIME):
    run_trim(
        ['als', PATH],
        EXIT_STDOUT
    )

if MIME == b'application/pdf':
    run_trim(
        ['pdftotext', '-l', '10', '-nopgbrk', PATH, '-'],
        EXIT_STDOUT
    )

if MIME.startswith(b'image/'):
    run_trim(
        ['img2txt', f'--width={WIDTH}', PATH],
        EXIT_FIXHEIGHT
    )

# i have had issues identifying mimetypes for audio
# depending on the metadata, so i also check the
# extension
AUDIO_EXT = {
    'mp3',
    'flac',
    'opus',
    'ogg',
}
if (EXTENSIONS and EXTENSIONS[-1].lower() in AUDIO_EXT) or (MIME.startswith(b'audio/')):
    run_trim(
        ['beet', 'info', PATH],
        EXIT_STDOUT
    )

if MIME.startswith(b'video/'):
    # TODO: prune output to be more specific, using -show_entries
    run_trim(
        ['ffprobe', '-show_format' , '-show_streams', '-show_chapters', '-of', 'json', PATH],
        EXIT_STDOUT
    )

sys.exit(EXIT_NOPREVIEW)
