#!/bin/bash

usage() {
    echo "Phantom - Steganography Tool"
    echo "Usage:"
    echo "  $0 encode file \"message\" [password]"
    echo "  $0 decode file [password]"
    exit 1
}

# Check if file is binary or text
is_binary() {
    local file="$1"
    local mime=$(file --mime-type -b "$file")
    [[ "$mime" != text/* ]] && return 0 || return 1
}

str_to_bin() {
    echo -n "$1" | xxd -b | cut -d' ' -f2-7 | tr -d ' \n'
}

bin_to_str() {
    echo -n "$1" | perl -lpe '$_=pack("B*",$_)' 2>/dev/null
}

encrypt() {
    echo -n "$1" | openssl enc -aes-256-cbc -pbkdf2 -base64 -A -salt -pass pass:"$2" 2>/dev/null
}

decrypt() {
    echo -n "$1" | openssl enc -aes-256-cbc -pbkdf2 -base64 -A -d -salt -pass pass:"$2" 2>/dev/null
}

# Text file steganography using whitespace
encode_text() {
    local file="$1"
    local message="$2"
    local temp=$(mktemp)

    local bin_msg=$(str_to_bin "$message")
    echo "Debug: Binary length = ${#bin_msg}"

    local lines=$(wc -l < "$file")
    if [ "$lines" -lt "${#bin_msg}" ]; then
        echo "Error: File needs at least ${#bin_msg} lines (has $lines)" >&2
        rm -f "$temp"
        exit 1
    fi

    local i=0
    while IFS= read -r line; do
        line="${line%"${line##*[![:space:]]}"}"
        if [ "$i" -lt "${#bin_msg}" ]; then
            if [ "${bin_msg:$i:1}" = "1" ]; then
                echo "$line " >> "$temp"
            else
                echo -e "$line\t" >> "$temp"
            fi
        else
            echo "$line" >> "$temp"
        fi
        ((i++))
    done < "$file"

    mv "$temp" "$file"
}

decode_text() {
    local file="$1"
    local bin_msg=""

    while IFS= read -r line; do
        if [[ "$line" =~ [[:space:]]$ ]]; then
            if [[ "$line" =~ \ $ ]]; then
                bin_msg+="1"
            elif [[ "$line" =~ $'\t'$ ]]; then
                bin_msg+="0"
            fi
        fi
    done < "$file"

    [ -z "$bin_msg" ] && { echo "No hidden message found" >&2; exit 1; }
    bin_to_str "$bin_msg"
}

# Binary file steganography using LSB
encode_binary() {
    local file="$1"
    local message="$2"
    local temp=$(mktemp)

    # Convert message to binary and add length header
    local bin_msg=$(str_to_bin "$message")
    local msg_len=${#bin_msg}
    local len_header=$(printf '%032d' "$(echo "obase=2;$msg_len" | bc)")
    bin_msg="$len_header$bin_msg"

    # Copy first 512 bytes (headers) unchanged
    dd if="$file" of="$temp" bs=512 count=1 2>/dev/null

    # Embed message after header
    local offset=512
    local i=0
    while [ $i -lt ${#bin_msg} ]; do
        local byte=$(xxd -s $((offset+i)) -l 1 -p "$file")
        [ -z "$byte" ] && break
        local new_byte=$((0x$byte & 0xFE | ${bin_msg:i:1}))
        printf '%02x' $new_byte | xxd -r -p | dd of="$temp" bs=1 seek=$((offset+i)) conv=notrunc 2>/dev/null
        ((i++))
    done

    # Copy rest of file
    dd if="$file" of="$temp" bs=1 skip=$((offset+i)) seek=$((offset+i)) 2>/dev/null
    mv "$temp" "$file"
}

decode_binary() {
    local file="$1"
    local bin_msg=""
    local i=0
    local offset=512

    # Read length header (32 bits)
    while [ $i -lt 32 ]; do
        local byte=$(xxd -s $((offset+i)) -l 1 -p "$file")
        [ -z "$byte" ] && break
        bin_msg+=$((0x$byte & 0x01))
        ((i++))
    done

    [ ${#bin_msg} -lt 32 ] && { echo "No hidden message found" >&2; exit 1; }
    local msg_len=$((2#$bin_msg))
    bin_msg=""

    # Read message bits
    while [ ${#bin_msg} -lt $msg_len ]; do
        local byte=$(xxd -s $((offset+i)) -l 1 -p "$file")
        [ -z "$byte" ] && break
        bin_msg+=$((0x$byte & 0x01))
        ((i++))
    done

    bin_to_str "$bin_msg"
}

[ $# -lt 2 ] && usage

op="$1"
file="$2"
[ ! -f "$file" ] && { echo "File not found: $file" >&2; exit 1; }

case "$op" in
    encode)
        [ $# -lt 3 ] && usage
        message="$3"
        password="$4"

        if [ -n "$password" ]; then
            message=$(encrypt "$message" "$password")
        fi

        if is_binary "$file"; then
            encode_binary "$file" "$message"
        else
            encode_text "$file" "$message"
        fi
        echo "Message hidden successfully"
        ;;
    decode)
        if is_binary "$file"; then
            message=$(decode_binary "$file")
        else
            message=$(decode_text "$file")
        fi

        password="$3"
        if [ -n "$password" ]; then
            decrypted=$(decrypt "$message" "$password")
            if [ $? -ne 0 ] || [ -z "$decrypted" ]; then
                echo "Decryption failed (wrong password?)" >&2
                exit 1
            fi
            message="$decrypted"
        fi

        echo "$message"
        ;;
    *)
        usage
        ;;
esac
