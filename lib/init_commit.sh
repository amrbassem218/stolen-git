#!/bin/bash

ruby stg.rb init

count=0
while IFS= read -r file && [ $count -lt 5 ]; do
    file="${file#./}"
    ruby stg.rb stage "$file"
    ruby stg.rb commit -n "$file"
    ((count++))
done < <(find . -maxdepth 1 -type f)

if [ -d "test" ]; then
    count=0
    while IFS= read -r file && [ $count -lt 5 ]; do
        ruby stg.rb stage "$file"
        ruby stg.rb commit -n "test-$((count + 1))"
        ((count++))
    done < <(find test -maxdepth 1 -type f)
fi
