#!/bin/bash

set -eu

unshare_again() {
    unshare --map-user=1000 "$@"
}
export -f unshare_again

add_netdev() {
    printf '[NetDev]\nName = wg0\n\n' > /etc/systemd/network/90-wireguard.netdev
    "$@"
}
export -f add_netdev

_run_test() {
    local test=$1
    local wrapper=${2:-}
    local command=${test%%/*}
    local has_stdin=0 expres=0 error=0
    local args= regexp res
    [[ -f ${test}.stdin ]] && has_stdin=1
    [[ -f ${test}.args ]] && args="$(<${test}.args)"
    
    # We are in our own mount namespace and pretend to be root:
    # Mount over /run first, bind-mount original /etc to /run/etc, because we
    # need /etc/alternatives and then mount over /etc to mask actual system
    # configuration and allow tests to write files.
    mount -t tmpfs tmpfs /run
    mkdir -p /run/etc
    mount --bind /etc /run/etc
    mount -t tmpfs tmpfs /etc

    # Required for awk on some distributions
    ln -s /run/etc/alternatives /etc/alternatives
    # Required for `id -un`
    echo "root:x:0:0:root:/root:/bin/bash" > /etc/passwd

    # Create the directories we care about
    mkdir -p /etc/wireguard /etc/systemd/network
    # Copy the tests hooks if necessary
    [[ -d "${test}" ]] && cp -r "${test}" /etc/wg-setup

    # Create the configuration file to test
    test_file=/etc/systemd/network/90-wireguard.netdev
    if [[ -f ${test}.conf ]]; then
        test_file=/etc/wireguard/wg0.conf
        cp ${test}.conf ${test_file}
    elif [[ -f ${test}.netdev ]]; then
        cp ${test}.netdev ${test_file}
    else
        printf '[NetDev]\nName = wg0\n\n' > ${test_file}
    fi

    # Run wg-setup
    if [[ $has_stdin -eq 1 ]]; then
        ! ${wrapper} wg-setup ${command} ${args} <${test}.stdin 1>/run/stdout 2>/run/stderr
    else
        ! ${wrapper} wg-setup ${command} ${args} 1>/run/stdout 2>/run/stderr
    fi

    # Evaluate the results
    res=${PIPESTATUS[0]}
    [[ -f ${test}.result ]] && expres=$(<${test}.result)
    if [[ $res -ne $expres ]]; then
        echo "Test ${test} failed: Exit code $res doesn't match expected exit code $expres!"
        error=1
    fi
    regexp=""
    [[ -f ${test}.expected ]] && regexp=$(<${test}.expected)
    if [[ ! "$(<${test_file})" =~ ^${regexp}$ ]]; then
        echo "Test ${test} failed: Output file doesn't match expectation!"
        cat ${test_file}
        error=1
    fi
    regexp=""
    [[ -f ${test}.stdout ]] && regexp=$(<${test}.stdout)
    if [[ ! "$(</run/stdout)" =~ ^${regexp}$ ]]; then
        echo "Test ${test} failed: Stdout doesn't match expectation!"
        cat /run/stdout
        error=1
    fi
    regexp=""
    [[ -f ${test}.stderr ]] && regexp=$(<${test}.stderr)
    if [[ ! "$(</run/stderr)" =~ ^${regexp}$ ]]; then
        echo "Test ${test} failed: Stderr doesn't match expectation!" 
        cat /run/stderr
        error=1
    fi
    if [[ $error -eq 0 ]]; then
        echo "Test ${test} passed!"
    fi
    return $error
}
export -f _run_test

run_test() {
    unshare --mount --map-root-user bash -c "_run_test $*"
}

export WG_TEST=1
export PATH=$(realpath ..):${PATH}
export LANG=en_US.UTF-8

run_test add-peer/interactive-success
run_test add-peer/interactive-success-nocidr
run_test add-peer/interactive-y-success
run_test add-peer/interactive-error-abort
run_test add-peer/interactive-error-no-name
run_test add-peer/interactive-error-no-pubkey
run_test add-peer/interactive-error-no-allowedips
run_test add-peer/interactive-error-invalid-name
run_test add-peer/interactive-error-invalid-pubkey
run_test add-peer/interactive-error-invalid-allowedips
run_test add-peer/interactive-error-name-exists
run_test add-peer/interactive-error-pubkey-exists
run_test add-peer/interactive-error-allowedips-exists

run_test add-peer/args-success
run_test add-peer/args-f-success
run_test add-peer/args-f-conf-success
run_test add-peer/args-i-success
run_test add-peer/args-two-files-success add_netdev
run_test add-peer/args-success-hooks
run_test add-peer/args-y-success
run_test add-peer/args-error-abort
run_test add-peer/args-error-too-few-arguments
run_test add-peer/args-error-name-exists
run_test add-peer/args-error-pubkey-exists
run_test add-peer/args-error-allowedips-exists
run_test add-peer/args-error-f-file-not-found
run_test add-peer/args-error-f-ifname-not-found
run_test add-peer/args-error-f-i-conflict
run_test add-peer/args-error-wg0-file-not-found
run_test add-peer/args-error-must-be-root unshare_again

run_test remove-peer/interactive-success
run_test remove-peer/interactive-success-by-ip
run_test remove-peer/interactive-success-by-name
run_test remove-peer/interactive-y-success
run_test remove-peer/interactive-error-pubkey-not-found
run_test remove-peer/interactive-error-abort
run_test remove-peer/interactive-success-malformed
run_test remove-peer/interactive-success-noblank
run_test remove-peer/interactive-success-noblank2
run_test remove-peer/interactive-success-extra

run_test remove-peer/args-success
run_test remove-peer/args-success-hooks
run_test remove-peer/args-success-by-ip
run_test remove-peer/args-success-by-name
run_test remove-peer/args-y-success
run_test remove-peer/args-error-too-many-arguments
run_test remove-peer/args-error-pubkey-not-found
run_test remove-peer/args-error-multiple
run_test remove-peer/args-error-abort
run_test remove-peer/args-error-must-be-root unshare_again

run_test list-peers/args-none
run_test list-peers/args-hosts
run_test list-peers/args-added
run_test list-peers/args-pubkeys
run_test list-peers/args-dns-zone
run_test list-peers/args-invalid
run_test list-peers/args-too-many
