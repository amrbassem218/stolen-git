<div align="center">
  <h1>Stolen Git</h1>
  <span>
    Have you ever wanted to use Git but it's too good?
  </span>
</div>
<br>

## What is stolen git? \ Why?

Stolen git is well... you get it. I'm building a mini git clone to learn version control and get comfortable with ruby.

## Commands

| Command  | description                                                       | Flags                                                                                              |
| -------- | ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| init     | Initialize the project                                            | N/A                                                                                                |
| stage    | add a file or directory to be tracked                             | N/A                                                                                                |
| commit   | Save the current tracked state                                    | `-n [--name]` <br> `-d [--description]`                                                            |
| diff     | get the difference between working directory and the last commit  | N/A                                                                                                |
| log      | print out commit history (limit print by a number `log <number>`) | N/A                                                                                                |
| checkout | check a commit or a branch without loss in data                   | `-c [--commit] <commit_id>` to check out a commit instaed of a branch wihout changing HEAD pointer |
| branch   | List all branches. (or creating a branch by `branch <name>`)      | N/A                                                                                                |

## Tech stack

Just ruby... (for now at least)
