<div align="center">
  <h1>Stolen Git</h1>
  <span>
    Have you ever wanted to use Git but it's too good?
  </span>
</div>
<br>

## What is stolen git? \ Why?

Stolen git is well... you get it. I'm building a mini git clone to learn version control and get comfortable with ruby.

## Usage

Run `stg init` once in a project before using the other commands. Stolen Git stores its data in `.stolen-git/` and tracks files through its own index.

| Command                   | Description                                                                                                            | Options                                                |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `init`                    | Initialize `.stolen-git/` in the current directory.                                                                    | N/A                                                    |
| `stage <file...>`         | Add files or directories to the Stolen Git index. Directories are staged recursively.                                  | N/A                                                    |
| `commit`                  | Save the current indexed state as a commit.                                                                            | `-n, --name NAME` <br> `-d, --description DESCRIPTION` |
| `diff`                    | Show differences between the working directory and the last commit.                                                    | N/A                                                    |
| `log [limit]`             | Print commit history. Pass a limit to show only the latest entries.                                                    | N/A                                                    |
| `reset [commit_id]`       | With no id, restore working files from the index. With an id, restore that commit and move the current branch pointer. | N/A                                                    |
| `checkout <name>`         | Check out a branch by name.                                                                                            | N/A                                                    |
| `checkout -c <commit_id>` | Check out a commit without moving the current branch pointer.                                                          | `-c, --commit`                                         |
| `branch [name]`           | List all branches, or create a branch when a name is provided.                                                         | N/A                                                    |
| `help`                    | Print the command list.                                                                                                | N/A                                                    |

For more detail on staging, committing, and reset behavior, see [COMMANDS.md](COMMANDS.md).

## Installation

1. Make sure you have Ruby installed on your system. You can check by running:

   ```
   ruby -v
   ```

   (If you don't have Ruby, visit [ruby-lang installation](https://www.ruby-lang.org/en/documentation/installation/) to get set up.)

2. Install the Gem  
   Run the following command in your terminal:

   ```
   gem install stg

   # you may need administrative permission, in this case
   sudo gem install stg
   ```

Run `stg` to verify your installation

## Examples

> [!NOTE]
> You have to initialize with `stg init` for any of the other commands to work

### Start a new project

```sh
stg init
stg stage .
stg commit -n "Initial commit"
```

### Save a file change

```sh
stg stage lib/stg/actions.rb
stg commit -n "Improve reset validation"
```

### Inspect history

```sh
stg log # Show 5 logs and waits for user confirmation to continue
stg log 3 # Shows last 3 commits in the branch and closes
```

### Discard unstaged working changes

```sh
stg stage README.md
# edit README.md again
stg reset
```

`README.md` is restored to the version stored in the index (a.k.a last version of the file you staged).

### Reset to a previous commit

> [!WARNING]
> `stg reset <commit_id>` is destructive. It moves the branch pointer back and can make later Stolen Git commits unreachable. Use `stg checkout -c <commit_id>` if you only want to inspect an older commit.

```sh
stg log # shows all commits with commit_id next to the word commit in green
stg reset <commit_id>
```

### Help

```sh
stg
stg help
```
