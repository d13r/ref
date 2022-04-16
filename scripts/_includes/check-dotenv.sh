dotenv_has_warnings=false

if [ "$(type -t colorize)" != 'function' ]; then
    source 'scripts/_includes/colors.sh'
fi

check_dotenv_exists()
{
    if [ ! -f .env ]; then
        red ".env file doesn't exist" >&2
        exit 1
    fi
}

check_dotenv_includes()
{
    local vars="$@"
    local error=false

    for var in $vars; do
        if ! grep -q "^$var=" .env; then
            red "Error: .env is missing a required setting: $var"
            error=true
        fi
    done

    if $error; then
        exit 1
    fi
}

dotenv_setting_names()
{
    local file="${1:-.env}"

    grep -oP '^[a-zA-Z0-9_]+(?==)' "$file"
}

check_dotenv_against()
{
    local other="$1"

    check_dotenv_exists

    for var in $(dotenv_setting_names); do
        if ! grep -q "^#\?$var=" .env.example; then
            yellow "Warning: .env includes an unknown setting: $var"
            dotenv_has_warnings=true
        fi
    done

    check_dotenv_includes "$(dotenv_setting_names .env.example)"
}
