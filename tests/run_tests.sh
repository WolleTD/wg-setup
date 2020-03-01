#!/bin/bash

run_test() {
    local test=$1
    local command=${test%%/*}
    local has_stdin=0 expres=0 error=0
    local args regexp res
    [[ -f ${test}.stdin ]] && has_stdin=1
    [[ -f ${test}.args ]] && args=$(<${test}.args)
    
    tmpdir=$(mktemp -d)

    if [[ -f ${test}.infile ]]; then
        cp ${test}.infile ${tmpdir}/infile
        test_file=${tmpdir}/infile
    else
        echo "Error: testing without testfile is a stub!" >&2
        exit 1
    fi
    
    if [[ $has_stdin -eq 1 ]]; then
        ${command} "${test_file}" "${args}" <${test}.stdin 1>${tmpdir}/stdout 2>${tmpdir}/stderr
    else
        ${command} "${test_file}" "${args}" 1>${tmpdir}/stdout 2>${tmpdir}/stderr
    fi
    res=$?
    [[ -f ${test}.result ]] && expres=$(<${test}.result)
    if [[ $res -ne $expres ]]; then
        echo "Test ${test} failed: Exit code $res doesn't match expected exit code $expres!"
        error=1
    fi
    regexp=$(<${test}.infile)
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
    if [[ $error -eq 0 ]]; then
        echo "Test ${test} passed!"
    fi
    rm -rf ${tmpdir}
    return $error
}

export WG_TEST=1
export PATH=$(realpath ..):${PATH}
export LANG=en_US.UTF-8

run_test add-wg-peer/interactive
