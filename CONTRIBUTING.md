# Contributing to the Osiris DRP

## Reporting Issues

Please report [issues](https://github.com/Keck-DataReductionPipelines/OsirisDRP/issues) on GitHub to the [OsirisDRP repository](https://github.com/Keck-DataReductionPipelines/OsirisDRP). Please include the version of IDL you are using, and the shell you are using.

## Contributing code
So you're interested in contributing code to to the OsirisDRP? Excellent!

Most contributions to OsirisDRP are done via pull requests from GitHub users'
forks of the [OsirisDRP repository](https://github.com/astropy/astropy). If you're new to this style of development,
Astropy has a good summary of this [development workflow](http://docs.astropy.org/en/latest/development/workflow/development_workflow.html), but we'll describe it for the OsirisDRP below.

### Getting the development version

First, you'll need an account on [GitHub](http://github.com). Then go to <https://github.com/Keck-DataReductionPipelines/OsirisDRP> and click on the "Fork" button in the upper right hand corner. This will make a "Forked" copy of the Osiris DRP in your GitHub Account.

Then, clone the OsirisDRP to your computer:

```
    
    $ git clone https://github.com/your-user-name/OsirisDRP.git
    Cloning into 'OsirisDRP'...
    remote: Counting objects: 2386, done.
    remote: Compressing objects: 100% (97/97), done.
    remote: Total 2386 (delta 60), reused 0 (delta 0), pack-reused 2288
    Receiving objects: 100% (2386/2386), 5.41 MiB | 957.00 KiB/s, done.
    Resolving deltas: 100% (1674/1674), done.
    Checking connectivity... done.
    $ cd OsirisDRP/
    $ git checkout develop
```

Now, you need to set your repository up so that you can collect the latest changes from the Keck version of the OsirisDRP. To do this, add a git remote (called ``upstream`` by convention):

```
    $ git remote add upstream https://github.com/Keck-DataReductionPipelines/OsirisDRP.git
    $ git fetch upstream
    Fetching upstream
    remote: Counting objects: 630, done.
    remote: Compressing objects: 100% (78/78), done.
    remote: Total 630 (delta 68), reused 30 (delta 30), pack-reused 522
    Receiving objects: 100% (630/630), 1.31 MiB | 365.00 KiB/s, done.
    Resolving deltas: 100% (86/86), completed with 24 local objects.
    From https://github.com/Keck-DataReductionPipelines/OsirisDRP
     * [new branch]      develop    -> upstream/develop
     * [new branch]      master     -> upstream/master
```

To get the latest changes to the development version of the pipeline, pull from ``upstream/develop``

```
    $ git pull upstream develop
    From https://github.com/Keck-DataReductionPipelines/OsirisDRP
     * branch            develop    -> FETCH_HEAD
    Already up-to-date.
```

### Making changes

Now make your awesome changes to the pipeline! When you are done, commit them to your git repository.

For example, lets pretend you've added ``my-awesome-file``

```
    $ git add my-awesome-file
    $ git commit
```

### Testing your changes

The OSIRIS Data reduction pipeline has a testing framework. It requires ``python``, ``py.test`` and ``astropy``. If you use anaconda for your python you can install ``py.test`` and ``astropy`` with ``$ conda install pytest astropy``. If you have a standard python installation, you can try installing ``py.test`` and ``astropy`` using pip, with ``$ pip install pytest astropy``.

To test your changes, you can use the existing test framework. You can find information on writing new tests in ``tests/README.md``. You can then run your tests with ``make test``

```
    $ make test
```

### Giving your changes back to the community

Now you need to publish your changes to GitHub:

```
    $ git push develop
```

Then, you can go to your repository on GitHub (e.g. <http://github.com/your-github-username/OsirisDRP.git>), and there should be a button there to create a pull request. Create the pull request, add a description!

### Things to consider about your pull request

Once you open a pull request (which should be opened against the ``develop``
branch, not against any of the other branches), please make sure that you
include the following:

- **Code**: the code you are adding, which should follow as much as possible
  our [coding guidelines](http://docs.astropy.org/en/latest/development/codeguide.html).

- **Tests**: these are usually tests that ensures that code that previously
  failed now works (regression tests) or tests that cover as much as possible
  of the new functionality to make sure it doesn't break in future, and also
  returns consistent results on all platforms (since we run these tests on many
  platforms/configurations). For more information about how to write tests, see
  ``tests/README.md``.

- **Changelog entry**: whether you are fixing a bug or adding new
  functionality, you should add an entry to the ``CHANGES.rst`` file that
  includes if possible the issue number (if you are opening a pull request you
  may not know this yet, but you can add it once the pull request is open). If
  you're not sure where to put the changelog entry, wait at least until a
  maintainer has reviewed your PR and assigned it to a milestone.

  You do not need to include a changelog entry for fixes to bugs introduced in
  the developer version and which are not present in the stable releases.  In
  general you do not need to include a changelog entry for minor documentation
  or test updates.  Only user-visible changes (new features/API changes, fixed
  issues) need to be mentioned.  If in doubt ask the core maintainer reviewing
  your changes.

