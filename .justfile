create-post name:
    hugo new content ./content/posts/{{name}}

update-theme:
    git submodule update --remote themes/nightfall

