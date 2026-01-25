#!/usr/bin/env bash

GETTEST_EDITOR=$EDITOR
GETTEST_DIR=${XDG_DATA_HOME:-$HOME/.local/share/gettest}

# source .env files
set -a && source *.env && set +a

GETTEST_TEMPLATE_DIR=${GETTEST_TEMPLATE_DIR:-"${GETTEST_DIR}/templates"}
GETTEST_PROJECTS_DIR=${GETTEST_PROJECTS_DIR:-"${GETTEST_DIR}/projects"}

CLR_RED="\x1b[31m"
CLR_GREEN="\033[38;5;41m"
CLR_RESET="\x1b[0m"

BUILTIN_TEMPLATE_MAX_LEN=6 # python

main() {
    local args=()
    while [[ -n $1 ]]; do
        case "$1" in
            -h | --help)
                print_help
                exit 0
                ;;
            -d | --delete)
                delete_projects
                exit 0
                ;;
            *)
                args+=("$1")
                ;;
        esac
        shift
    done

    if [[ -z "$args" ]]; then
        open_project
    else
        new_project "${args[@]}"
    fi
}

print_help() {
    echo -e "gettest [options] [template] [name...]" >&2
    echo -e "" >&2
    echo -e "Arguments:" >&2
    echo -e "\ttemplate           The template to open" >&2
    echo -e "\tname               Name to store the project as" >&2
    echo -e "" >&2
    echo -e "Options:" >&2
    echo -e "\t-d, --delete       Select projects to delete"
    echo -e "\t-h, --help         Show this help message and exit" >&2
}

print_error() {
    local message=$1
    echo -e "${CLR_RED}error:${CLR_RESET} ${message}" >&2
}

print_info() {
    local message=$1
    echo -e "${CLR_GREEN}info:${CLR_RESET} ${message}" >&2
}

sanitize_name() {
    local input="$1"
    { tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'; } <<< "$input"
}

new_project() {
    local template=$(tr '[:upper:]' '[:lower:]' <<< "$1")
    shift
    local name="$@"

    local project_dir="$(get_project_dir "$template" "$name")"
    local now=$(date +'%Y/%m/%d %H:%M')

    template_path=$(realpath "${GETTEST_TEMPLATE_DIR}/${template}.sh")

    mkdir -p "${project_dir}"
    pushd "${project_dir}" >/dev/null

    local exit_code=0
    if [[ -f $template_path ]]; then
        if ! . "$template_path"; then
            print_error "Custom template script '$template_path' failed!"
            exit_code=1
        fi
    else
        case "$template" in
            p | plain)
                template=plain
                # no-op
                ;;
            s | sh | bash)
                template=bash
                template_bash
                ;;
            py | python)
                template=python
                template_python
                ;;
            go)
                template=go
                template_go
                ;;
            rust)
                template=rust
                template_rust
                ;;
            *)
                print_error "No template '${template}' found!"
                exit_code=1
                ;;
        esac
    fi

    popd >/dev/null

    if [[ $exit_code -gt 0 ]]; then
        rm -rf "${project_dir}"
        exit "$exit_code"
    fi

    if ! "$GETTEST_EDITOR" "$project_dir"; then
        print_error "Editor process failed '$GETTEST_EDITOR'"
        rm -rf "${project_dir}"
        exit 1
    fi

    if [[ -z $name ]]; then
        echo "You did not provide a project name. Do you now want to give your project a name?"
        echo "(Simply press ender to skip)"
        echo -en "\nName: "
        read -r name

        if [[ -n $name ]]; then
            local new_project_dir=$(get_project_dir "$template" "$name")
            mv "$project_dir" "$new_project_dir"
            project_dir="$new_project_dir"
        fi
    fi

    cat <<EOF > "${project_dir}/.gettest.meta"
name="$name"
date="$now"
template="$template"
EOF
}

get_project_dir() {
    local template=$1
    local name=$2

    if [[ -n $name ]]; then
        name=$(sanitize_name "$name")
    else
        name="$RANDOM"
    fi

    creation_date=$(date +'%Y%d%m-%H%M%S')

    echo "${GETTEST_PROJECTS_DIR}/${creation_date}.${template}.${name}"
}

search_projects() {
    local fzf_args=(
        --delimiter='\t'
        --with-nth=2..
        --tabstop=4
        --cycle
        --no-sort
    )

    if [[ $1 == "multi" ]]; then
        fzf_args+=("--multi")
    fi

    if [[ ! -d "${GETTEST_PROJECTS_DIR}" ]]; then
        print_error "No projects available to list."
        return 1
    fi

    max_template_name_len=$(find "${GETTEST_TEMPLATE_DIR}" -maxdepth 1 -type f -name '*.sh' 2>/dev/null \
        | awk '{ a = $0; sub(".*/", "", a); sub("\\.sh$", "", a); print length(a)}' \
        | sort -r \
        | head -1)

    if ! [[ $max_template_name_len -gt $BUILTIN_TEMPLATE_MAX_LEN ]]; then
        max_template_name_len=$BUILTIN_TEMPLATE_MAX_LEN
    fi

    for project in "${GETTEST_PROJECTS_DIR}"/*; do
        if source "${project}/.gettest.meta" 2>/dev/null; then
            printf "%s\t%s\t%-${max_template_name_len}s\t%s\n" "$project" "$date" "$template" "$name"
        fi
    done | sort -k 2 -k 1 -r | fzf "${fzf_args[@]}"
}

open_project() {
    if ! selected_entry=$(search_projects); then
        print_error "Aborted."
        exit 1
    fi

    if [[ -z $selected_entry ]]; then
        print_error "No project selected."
        exit 1
    fi

    read -r project_dir _ <<< "$selected_entry"

    if ! "$GETTEST_EDITOR" "$project_dir"; then
        print_error "Editor process failed '$GETTEST_EDITOR'"
        rm -rf "${project_dir}"
        exit 1
    fi
}

delete_projects() {
    export FZF_DEFAULT_OPTS="--header=\"Select projects to delete (tab to select multiple entries)\""
    if ! selected_entries=$(search_projects multi); then
        print_error "Aborted."
        exit 1
    fi

    if [[ -z $selected_entries ]]; then
        print_error "No project selected."
        exit 1
    fi

    local deleted=0
    local failed=1
    while read -r dir _; do
        if rm -r "$dir"; then
            ((deleted++))
        else
            ((failed++))
        fi
    done <<< "$selected_entries"

    print_info "Deleted $deleted projects."

    if [[ $failed -gt 0 ]]; then
        print_error "Failed to delete $failed projects."
    fi
}

##### BUILTIN TEMPLATES #####

template_bash() {
    echo -e "#!/usr/bin/env bash\n" > main.sh
    chmod +x main.sh
}

template_python() {
    echo -e "#!/usr/bin/env python3\n" > main.py
    chmod +x main.py
}

template_go() {
    go mod init test >/dev/null
    cat <<EOF > main.go
package main

func main() {

}
EOF
}

template_rust() {
    cargo init . --bin --vcs none --quiet --name testproject
}

#############################

main "$@"
