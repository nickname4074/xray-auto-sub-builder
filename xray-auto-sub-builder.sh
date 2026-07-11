#!/usr/bin/env bash

SCRIPT_NAME="$(basename $0)"

CONFIG_ENV_PATH="${PWD}/config.env"

# $* = message
die() {
    printf '%s: Error:   %s\n' "${SCRIPT_NAME}" "$*" >&2
    exit 1
}

# $* = message
log_error() {
    printf '%s: Error:   %s\n' "${SCRIPT_NAME}" "$*" >&2
}

# $* = message
log_warn() {
    printf '%s: Warning: %s\n' "${SCRIPT_NAME}" "$*" >&2
}

# $* = message
log_info() {
    printf '%s: Info:    %s\n' "${SCRIPT_NAME}" "$*" >&2
}

if [[ -f "${CONFIG_ENV_PATH}" ]]; then
    source "${CONFIG_ENV_PATH}"
else
    die "${CONFIG_ENV_PATH} does not exit"
    exit 1
fi

# no args; no return
cleanup() {
    [[ -d "${TMP_DIR}" ]] && rm -rf "${TMP_DIR}" &> /dev/null
    kill 0
}

trap 'status=$?; log_info "exiting..." >&2; cleanup; exit "${status}"' EXIT INT

# no args; no return
validate_config() {

    # $1 = number
    # returns 0/1
    is_int() {
        [[ "$1" =~ ^-?[0-9]+$ ]]
    }

    # $1 = number
    # returns 0/1
    is_bool() {
        [[ "$1" == "0" || "$1" == "1" ]]
    }

    # === BASIC SETTINGS ===

    # CHECK_INTERVAL
    is_int "${CHECK_INTERVAL}" || die "validate_config: CHECK_INTERVAL must be an integer: ${CHECK_INTERVAL}"

    # SOURCE_LIST_FILE
    [[ -n "${SOURCE_LIST_FILE}" ]] || die "validate_config: SOURCE_LIST_FILE is empty"
    [[ -f "${SOURCE_LIST_FILE}" ]] || die "validate_config: SOURCE_LIST_FILE does not exists: ${SOURCE_LIST_FILE}"
    [[ -r "${SOURCE_LIST_FILE}" ]] || die "validate_config: SOURCE_LIST_FILE is not readable: ${SOURCE_LIST_FILE}"
    [[ -s "${SOURCE_LIST_FILE}" ]] || die "validate_config: SOURCE_LIST_FILE: file ${SOURCE_LIST_FILE} is empty"

    # OUT_FILE
    [[ -n "${OUT_FILE}" ]] || die "validate_config: OUT_FILE is empty"
    [[ ! -d "${OUT_FILE}" ]] || die "validate_config: OUT_FILE is a directory: ${OUT_FILE}"

    # XRAY_KNIFE_HTTP_ARGS
    [[ "$(declare -p XRAY_KNIFE_HTTP_ARGS 2> /dev/null)" == declare\ -a* ]] \
        || die "validate_config: XRAY_KNIFE_HTTP_ARGS must be a bash array" 

    is_int "${MAX_VALID_NODES}" || die "validate_config: MAX_VALID_NODES must be an integer: ${MAX_VALID_NODES}"

    # === FLAGS (0/1) ===

    # NET_FAULT_TOLERANCE
    is_bool "${NET_FAULT_TOLERANCE}" || die "validate_config: NET_FAULT_TOLERANCE must be a 0 or 1"

    # === OTHER SETTINGS ===

    # TMP_PARENT_DIR
    [[ -n "${TMP_PARENT_DIR}" ]] || die "validate_config: TMP_PARENT_DIR is empty"
    mkdir -p "${TMP_PARENT_DIR}" || die "validate_config: Cannot create TMP_PARENT_DIR: ${TMP_PARENT_DIR}"

    local test_tmp="$(mktemp -d "${TMP_PARENT_DIR%/}/.test.XXXXXX")" \
        || die "validate_config: Cannot create temporary directory inside: ${TMP_PARENT_DIR}"
        
    rm -rf "${test_tmp}" || die "validate_config: Cannot remove test_tmp directory: ${test_tmp}"

    # LOCK_FILE
    [[ -n "${LOCK_FILE}" ]] || die "validate_config: LOCK_FILE is empty"

    local lock_dir="$(dirname -- "${LOCK_FILE}")"

    mkdir -p "${lock_dir}" || die "validate_config: Cannot create LOCK_FILE directory: ${lock_dir}"
    [[ -d "${lock_dir}" ]] || die "validate_config: LOCK_FILE directory is not a directory: ${lock_dir}"
    [[ -w "${lock_dir}" ]] || die "validate_config: LOCK_FILE directory is not a writable: ${lock_dir}"

    # === BINARY PATHS ===
    
    # XRAY_KNIFE_BIN
    
    [[ -n "${XRAY_KNIFE_BIN}" ]] || die "validate_config: XRAY_KNIFE_BIN is empty"
    [[ -x "${XRAY_KNIFE_BIN}" ]] || die "validate_config: XRAY_KNIFE_BIN is not executable: ${XRAY_KNIFE_BIN}"

    # === REQUIRED COMMANDS ===
    # command -v flock &> /dev/null || die "validate_config: flock is not installed"
}

# no args; no return
lock() {
    exec 9>"${LOCK_FILE}"
    flock -n 9 || die "main: another instance is already running"
}

# no args
# global variables:
# TMP_DIR
# UNITED_LINKS_FILE
# DB_TMP_DIR
init_runtime() {

    # TMP_DIR
    TMP_DIR="$(mktemp -d "${TMP_PARENT_DIR%/}/.tmp_dir_XXXXXX")"

    # DB_TMP_DIR
    DB_TMP_DIR="$(mktemp -d "${TMP_DIR%/}/.db_tmp_dir_XXXXXX")"

    # UNITED_LINKS_FILE
    UNITED_LINKS_FILE="${TMP_DIR%/}/UNITED_LINKS_FILE.txt"
    : > "${UNITED_LINKS_FILE}"
}

# no args
# out into UNITED_LINKS_FILE
# returns 1 if failed
fetch_sources() {

    HOME="${DB_TMP_DIR}" "${XRAY_KNIFE_BIN}" subs fetch -f "${SOURCE_LIST_FILE}" -o- > "${UNITED_LINKS_FILE}" \
        || { log_error "fetch_sources"; return 1; }
}

# takes links from UNITED_LINKS_FILE
# no return
dedupe_links() {

    local tmp_file
    tmp_file="$(mktemp "${TMP_DIR%/}/dedupe_links.XXXXXX")"

    sort -u < "${UNITED_LINKS_FILE}" > "${tmp_file}"
    mv "${tmp_file}" "${UNITED_LINKS_FILE}"
}

# takes linnks from UNITED_LINKS_FILE
# to OUT_FILE
test_links() {

    local tmp_file1 tmp_file2
    tmp_file1="$(mktemp "${TMP_DIR%/}/test_links1.XXXXXX")"
    tmp_file2="$(mktemp "${TMP_DIR%/}/test_links2.XXXXXX")"

    HOME="${DB_TMP_DIR}" "${XRAY_KNIFE_BIN}" http "${XRAY_KNIFE_HTTP_ARGS[@]}" -f "${UNITED_LINKS_FILE}" -o "${tmp_file1}"

    perl -0777 -pe 's/\n{2,}/\n/g' "${tmp_file1}" > "${tmp_file2}"

    if (( MAX_VALID_NODES > 0 )); then
        head -n "${MAX_VALID_NODES}" "${tmp_file2}" > "${OUT_FILE}"
    else
        mv "${tmp_file2}" "${OUT_FILE}"
    fi
}

# no args; no return
main() {

    # $1 = i
    # prints to stderr
    wait_animation() {
        
        local i dots dots_max_count

        i="$1"
        dots=''
        dots_max_count='3'

        while ((i != 0)); do

            dots="$(printf '%*s' "$((i % (dots_max_count + 1)))" '' | tr ' ' '.')"

            printf '\r\033[Kwaiting %s%s' "${i}" "${dots}" >&2
            
            ((i--))

            sleep 1

        done

        printf '\n' >&2
    }

    validate_config
    lock
    init_runtime

    if ((CHECK_INTERVAL >= 0)); then
        while true; do
        
            if (( NET_FAULT_TOLERANCE )); then
                while true; do
                    fetch_sources && break
                done
            else
                fetch_sources || exit 1
            fi
            
            dedupe_links
            test_links

            rm -rf "${DB_TMP_DIR%/}/*" &> /dev/null

            wait_animation "${CHECK_INTERVAL}" &
            sleep "${CHECK_INTERVAL}"
        
        done

    else

        if (( NET_FAULT_TOLERANCE )); then   
            while true; do
                fetch_sources && break
            done
        else
            fetch_sources || exit 1
        fi

        dedupe_links
        test_links

        rm -rf "${DB_TMP_DIR%/}/*" &> /dev/null

    fi
}

main
