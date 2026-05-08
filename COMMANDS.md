# Command Notes

This page has more detailed notes for Stolen Git commands. For a shorter command table and common examples, see [README.md](README.md).

## Table of contents

- [init](#init)
- [stage](#stage)
- [commit](#commit)
- [diff](#diff)
- [log](#log)
- [reset](#reset)
- [checkout](#checkout)
- [branch](#branch)
- [help](#help)

## init

> [!NOTE]
> Without initialization none of the other commands will work

Initializes Stolen Git in the current directory:

```sh
stg init
```

This creates `.stolen-git/`, `.stg-ignore`, the default `main` branch, and the internal files used for commits, branches, object storage, and the index.

If `.stolen-git/` already exists, `stg init` asks before replacing it. Confirming replacement deletes the existing Stolen Git history for that project.

## stage

Use `stage` to put files into Stolen Git's index:

```sh
stg stage README.md
stg stage lib test
stg stage .
```

`stg stage .` stages the current directory recursively. Dot-directories such as `.git/`, `.stolen-git/`, and other ignored paths are skipped according to `.stg-ignore`.

The index is the set of files that `stg commit` will use. Editing a file after staging it does not automatically update the index; run `stg stage <file>` again to stage the newer content.

Staging also records deletions for tracked files. If a tracked file is deleted from disk, run `stg stage .` or `stg stage <deleted_file>` before committing.

## commit

Commits are created from the index, not directly from every file in the working directory:

```sh
stg commit -n "Initial commit"
stg commit -n "Add reset behavior" -d "Restore files from the index when no commit id is provided"
```

If no name is provided with `-n` or `--name`, Stolen Git asks for one interactively.

If nothing has changed in the index compared to the current commit, Stolen Git prints that everything is up to date.

Commit output includes the number of changed files, insertions, and deletions. Those counts are based on differences between the previous commit tree and the current index.

## diff

Shows differences between tracked files in the working directory and the current index:

```sh
stg diff
```

For each indexed file, `diff` compares the saved blob in `.stolen-git/storage/blobs/` with the file currently on disk. Files with no working-directory changes are skipped.

If a tracked file is missing from the working directory, it is shown as deleted.

## log

Prints commit history starting from the current pointer:

```sh
stg log
```

Each log entry includes the commit id, shortened commit hash, author, date, and commit name.

By default, logs pause after 5 entries. Enter `q` at the prompt to stop, or `Enter` to print 1 more.

You can limit the number of entries:

```sh
stg log -5
stg log -l 5
stg log --limit 5
```

Use the commit ids printed by `stg log` with commands such as `stg reset <commit_id>` and `stg checkout -c <commit_id>`.

## reset

Reset has two modes:

```sh
stg reset
```

Restores tracked working-directory files from the current index. This is useful when you changed files after staging and want to discard those working-directory changes.

```sh
stg reset <commit_id>
```

Restores files from the selected commit and moves the current branch pointer to that commit. You can find commit ids with:

```sh
stg log
```

When resetting to a commit, tracked files that exist in the target commit are written to disk. Tracked files that exist in the current index but do not exist in the target commit are removed from disk.

If the commit id is invalid, Stolen Git prints:

```text
Usage: stg reset <commit_id>
You can find commit_id by running 'stg log'
```

## checkout

Checks out a branch by name:

```sh
stg checkout main
```

When checking out a branch, Stolen Git restores files from that branch's current commit and updates the pointer to that branch.

You can also check out a specific commit:

```sh
stg checkout -c <commit_id>
```

Commit checkout restores files from the selected commit without moving the current branch pointer.

## branch

Lists branches:

```sh
stg branch
```

The current branch is marked with `*`.

Creates one or more branches:

```sh
stg branch feature
stg branch feature-a feature-b
```

New branches start at the current commit. If the current pointer is a detached commit, new branches start from that commit.

## help

Prints the command list:

```sh
stg help
```

Running `stg` with no command prints the same command list.

You can also use `--help` on individual commands:

```sh
stg stage --help
stg commit --help
stg reset --help
```
