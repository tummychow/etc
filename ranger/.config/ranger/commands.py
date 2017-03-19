from ranger.api.commands import Command

class mcd(Command):
    """:mcd <dirname>
    Creates a directory with the name <dirname> and changes to it.
    """

    def execute(self):
        from os.path import join, expanduser, lexists
        from os import makedirs

        dirname = join(self.fm.thisdir.path, expanduser(self.rest(1)))
        if not lexists(dirname):
            makedirs(dirname)
        self.fm.thisdir.load_content(schedule=False)
        self.fm.cd(expanduser(self.rest(1)))

    def tab(self, tabnum):
        return self._tab_directory_content()
