#!/bin/bash -e

run_test() {
    local test=$1
    local command=${test%%/*}
    local has_stdin=0 expres=0 error=0
    local args regexp res toklist
    [[ -f ${test}.stdin ]] && has_stdin=1
    [[ -f ${test}.args ]] && args=$(<${test}.args)
    
    tmpdir=$(mktemp -d)

    if [[ -f ${test}.infile ]]; then
        cp ${test}.infile ${tmpdir}/infile
    else
        touch ${tmpdir}/infile
    fi
    export WG_TEST_FILE=${tmpdir}/infile

    if [[ -f ${test}.toklist ]]; then
        cp ${test}.toklist ${tmpdir}/toklist
    else
        touch ${tmpdir}/toklist
    fi
    export WG_TEST_TOKLIST=${tmpdir}/toklist
    
    if [[ $has_stdin -eq 1 ]]; then
        ! wg-setup ${command} ${args} <${test}.stdin 1>${tmpdir}/stdout 2>${tmpdir}/stderr
    else
        ! wg-setup ${command} ${args} 1>${tmpdir}/stdout 2>${tmpdir}/stderr
    fi
    res=${PIPESTATUS[0]}
    [[ -f ${test}.result ]] && expres=$(<${test}.result)
    if [[ $res -ne $expres ]]; then
        echo "Test ${test} failed: Exit code $res doesn't match expected exit code $expres!"
        error=1
    fi
    regexp=""
    [[ -f ${test}.expected ]] && regexp=$(<${test}.expected)
    if [[ ! "$(<${tmpdir}/infile)" =~ ^${regexp}$ ]]; then
        echo "Test ${test} failed: Output file doesn't match expectation!"
        cat ${tmpdir}/infile
        error=1
    fi
    regexp=""
    [[ -f ${test}.stdout ]] && regexp=$(<${test}.stdout)
    if [[ ! "$(<${tmpdir}/stdout)" =~ ^${regexp}$ ]]; then
        echo "Test ${test} failed: Stdout doesn't match expectation!"
        cat ${tmpdir}/stdout
        error=1
    fi
    regexp=""
    [[ -f ${test}.stderr ]] && regexp=$(<${test}.stderr)
    if [[ ! "$(<${tmpdir}/stderr)" =~ ^${regexp}$ ]]; then
        echo "Test ${test} failed: Stderr doesn't match expectation!" 
        cat ${tmpdir}/stderr
        error=1
    fi
    regexp=""
    [[ -f ${test}.expected-toklist ]] && regexp=$(<${test}.expected-toklist)
    if [[ ! "$(<${tmpdir}/toklist)" =~ ^${regexp}$ ]]; then
        echo "Test ${test} failed: Output tokenlist doesn't match expectation!"
        cat ${tmpdir}/toklist
        error=1
    fi
    if [[ $error -eq 0 ]]; then
        echo "Test ${test} passed!"
    fi
    rm -rf ${tmpdir}
    return $error
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
run_test add-peer/args-y-success
run_test add-peer/args-error-abort
run_test add-peer/args-error-too-few-arguments
run_test add-peer/args-error-name-exists
run_test add-peer/args-error-pubkey-exists
run_test add-peer/args-error-allowedips-exists

run_test remove-peer/interactive-success
run_test remove-peer/interactive-y-success
run_test remove-peer/interactive-error-pubkey-not-found
run_test remove-peer/interactive-error-abort
run_test remove-peer/interactive-success-malformed
run_test remove-peer/interactive-success-extra

run_test remove-peer/args-success
run_test remove-peer/args-y-success
run_test remove-peer/args-error-pubkey-not-found
run_test remove-peer/args-error-abort

run_test new-token/interactive-success
run_test new-token/interactive-error-name
run_test new-token/interactive-error-allowedips
run_test new-token/interactive-error-name-exists
run_test new-token/interactive-error-allowedips-exists

run_test new-token/args-success
run_test new-token/args-error-name
run_test new-token/args-error-allowedips
run_test new-token/args-error-name-exists
run_test new-token/args-error-allowedips-exists
run_test new-token/args-error-name-in-toklist
run_test new-token/args-error-allowedips-in-toklist

run_test use-token/args-success
run_test use-token/args-success-no-cidr
run_test use-token/args-wrong-token
run_test use-token/args-wrong-allowedips
run_test use-token/args-invalid-token
run_test use-token/args-invalid-allowedips
run_test use-token/args-invalid-publickey

run_test revoke-token/args-success
run_test revoke-token/args-invalid-token
run_test revoke-token/args-wrong-token

run_test list-tokens/args-success
run_test list-tokens/args-empty
