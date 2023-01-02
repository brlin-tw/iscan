#!/usr/bin/env bash
# Acquire non-free components from EPSON
ISCAN_VERSION="${ISCAN_VERSION:-2.30.4-2}"

set \
    -o errexit \
    -o nounset

# FALSE POSITIVE: Convenience variables
# shellcheck disable=SC2034
{
    script="${BASH_SOURCE[0]}"
    script_filename="${script##*/}"
    script_name="${script_filename%%.*}"
    script_dir="${script%/*}"
}

trap_err(){
    local script_name="${1}"; shift

    printf -- \
        '%s: Error: Program prematurely stopped due to an error.\n' \
        "${script_name}" \
        1>&2
}
trap 'trap_err "${script_name}"' ERR

trap_exit(){
    local script_name="${1}"; shift

    if test -v temp_dir \
        && test -e "${temp_dir}"; then
        if ! \
            rm \
                --recursive \
                "${temp_dir}"; then
            printf -- \
                '%s: Error: Unable to remove the temporary directory.\n' \
                "${script_name}" \
                1>&2
        fi
    fi
}
trap 'trap_exit "${script_name}"' EXIT

flag_runtime_environment_check_failed=false
declare -A required_command_to_display_name=(
    [curl]='cURL'
    [date]='GNU core utilities'
    [install]='GNU core utilities'
    [md5sum]='GNU core utilities'
    [mktemp]='GNU core utilities'
    [tar]='GNU tar'
    [gunzip]='GNU Gzip'
)
for required_command in "${!required_command_to_display_name[@]}"; do
    if ! command -v "${required_command}" >/dev/null; then
        flag_runtime_environment_check_failed=true
        printf -- \
            '%s: Error: This program requires the "%s" command to be available in your command search PATHs, this command should be provided by the "%s" software.\n' \
            "${script_name}" \
            "${required_command}" \
            "${required_command_to_display_name["${required_command}"]}" \
            1>&2
    fi
done
if test "${flag_runtime_environment_check_failed}" == true; then
    printf -- \
        '%s: Error: Runtime environment check failed, please check your installation.\n' \
        "${script_name}" \
        1>&2
    exit 1
fi

timestamp="$(
    date +%Y%m%d-%H%M%S
)"
temp_dir="$(
    mktemp \
        --tmpdir \
        --directory \
        "${script_name}.${timestamp}.XXX"
)"

printf -- \
    '%s: Info: Downloading upstream release archive...\n' \
    "${script_name}"
upstream_release_archive_filename="iscan_${ISCAN_VERSION}.tar.gz"
upstream_release_archive_url="https://support.epson.net/linux/src/scanner/iscan/${upstream_release_archive_filename}"
if ! \
    curl \
    --fail \
    --output-dir "${temp_dir}" \
    --remote-name \
    --silent \
    --show-error \
    "${upstream_release_archive_url}"; then
    printf -- \
        '%s: Error: Unable to download the upstream release archive.\n' \
        "${script_name}" \
        1>&2
    exit 2
fi
upstream_release_archive="${temp_dir}/${upstream_release_archive_filename}"

printf -- \
    '%s: Info: Extracting upstream release archive to temporary folder...\n' \
    "${script_name}"
if ! \
    tar \
        --extract \
        --directory "${temp_dir}" \
        --strip-components=1 \
        --file "${upstream_release_archive}"; then
    printf -- \
        '%s: Error: Unable to extract the upstream release archive.\n' \
        "${script_name}" \
        1>&2
    exit 3
fi

printf -- \
    '%s: Info: Installing non-free assets to the source tree...\n' \
    "${script_name}"
# How can I read a file (data stream, variable) line-by-line (and/or field-by-field)? - BashFAQ/001 - Greg's Wiki
# https://mywiki.wooledge.org/BashFAQ/001
declare -A non_free_assets_filename_to_checksum=()
while read -r checksum filename; do
    non_free_assets_filename_to_checksum["${filename}"]+="${checksum}"
done < "${script_dir}/checksums.md5"

for non_free_asset_filename in "${!non_free_assets_filename_to_checksum[@]}"; do
    # FALSE POSITIVE: The dont_care variable is designed to be unused
    # shellcheck disable=SC2034
    if ! \
        read -r file_checksum dont_care< <(
            md5sum \
                "${temp_dir}/non-free/${non_free_asset_filename}"
        ); then
        printf -- \
            '%s: Error: Unable to verify checksum for the "%s" non-free asset file.\n' \
            "${script_dir}" \
            "${non_free_asset_filename}" \
            1>&2
        exit 4
    fi

    if test "${file_checksum}" != "${non_free_assets_filename_to_checksum["${non_free_asset_filename}"]}"; then
        printf -- \
            '%s: Error: The checksum of the "%s" non-free asset file does not match the one that is recorded in this release, for your safety the program will not continue, please refer the issue tracker for assistance.\n' \
            "${script_name}" \
            "${non_free_asset_filename}" \
            1>&2
        exit 5
    fi
    install \
        --mode 0644 \
        --verbose \
        "${temp_dir}/non-free/${non_free_asset_filename}" \
        "${script_dir}/"
done

printf -- \
    '%s: Info: Program completed without errors.\n' \
    "${script_name}" \
    1>&2
