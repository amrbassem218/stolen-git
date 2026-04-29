#!/bin/bash

ruby main.rb init

count=0
while IFS= read -r file && [ $count -lt 5 ]; do
    file="${file#./}"
    ruby main.rb stage "$file"
    ruby main.rb commit -n "$((count + 1))"
    ((count++))
done < <(find . -maxdepth 1 -type f)
