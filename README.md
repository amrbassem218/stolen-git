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

| Command  | description                                                       | Flags                                                                                              |
| -------- | ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| init     | Initialize the project                                            | N/A                                                                                                |
| stage    | add a file or directory to be tracked                             | N/A                                                                                                |
| commit   | Save the current tracked state                                    | `-n [--name]` <br> `-d [--description]`                                                            |
| diff     | get the difference between working directory and the last commit  | N/A                                                                                                |
| log      | print out commit history (limit print by a number `log <number>`) | N/A                                                                                                |
| checkout | check a commit or a branch without loss in data                   | `-c [--commit] <commit_id>` to check out a commit instaed of a branch wihout changing HEAD pointer |
| branch   | List all branches. (or creating a branch by `branch <name>`)      | N/A                                                                                                |

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
   ```

Run `stg` to verify your installation

> [!NOTE]
> You have to initialize with `stg init` for any of the other commands to work
