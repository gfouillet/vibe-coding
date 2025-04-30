# This is vibe coding

This repository won't have any code written by me. Don't trust this code without reading it.

## [zipedit](scripts/zipedit.sh)

Used Junie from Jetbrain.

### Prompts

#### Initial commit

> Can you write a shell function which take a zip file as first argument, and a filepath inside the zip file as second argument.
>
> * completion on first argument is done by fetching local filesystem
> * completion on second argument is done by fetching zip file content
>
> when run, the function open a vim editor on the file designed by the filepath in the zip file. Once the vim editor is exited, all change are saved and the zip file is updated. 


> can you allow .zip and .charm (.charm are just zip file with an extension)

### Enhancement

> Can you update zipeditor.sh in order to make the completion a bit smarter ? I mean, instead of giving the full list of hiearchy inside the zip file, please update it step by step, like usual directory completion in bash ?

```txt
1. Examine the current zipeditor.sh script to understand how it works
2. Identify the part of the script that handles completion
3. Modify the completion logic to work step by step (like directory completion in bash)
- Update the `_zipedit_complete_archives` function to handle directory navigation
- Implement logic to show only files/directories at the current level
- Add support for navigating through directories with '/'
- Improve directory detection and add trailing slashes to directories at all levels
4. Test the changes to ensure they work as expected
5. Submit the solution
```

> this is almost what i want, but it is annoying, when you select a directory on the second argument, it add a space, which prevent to spam tab. In bash, if it is not ambiguous, it continue in depth, and if there is ambiguity, you will need to validate with return. Can we have the exact same behavior please ?

```txt
1. Examine the current zipeditor.sh script to understand how completion is currently implemented
2. Identify the issue with the space being added after directory selection
- The issue is in the `complete` command at line 181, which adds spaces by default
3. Modify the completion function to mimic bash's behavior:
- Add the `-o nospace` option to the `complete` command to prevent adding spaces after directory names
- This will allow continuous tab completion for directories
4. Test the changes to ensure they work as expected
5. Submit the solution
```