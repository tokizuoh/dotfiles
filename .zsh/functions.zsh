# Do `ls` when the current directory changes.
function chpwd() { ls }

# Switch default branch
function switch-default-branch-if-exists () {
    local git_directory=$(git rev-parse --show-toplevel)
    if [ -e "$git_directory/.git/refs/remotes/origin/HEAD" ]; then
        default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
        git switch $default_branch
    else
        echo "refs/remotes/origin/HEAD does not exist."
    fi
}
