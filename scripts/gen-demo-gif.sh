rm -rf data/projects
. "$(dirname "$0")/gen-projects.sh"
vhs "$(dirname "$0")/../.github/assets/demo.tape"
mv demo.gif "$(dirname "$0")/../.github/assets/demo.gif"
