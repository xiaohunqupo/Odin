package blake2b

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the BLAKE2b hashing algorithm.
    BLAKE2b and BLAKE2s share the implementation in the _blake2 package.
*/

import "core:io"
import "core:os"

import "../_blake2"

/*
    High level API
*/

DIGEST_SIZE :: 64

// hash_string will hash the given input and return the
// computed hash
hash_string :: proc(data: string) -> [DIGEST_SIZE]byte {
	return hash_bytes(transmute([]byte)(data))
}

// hash_bytes will hash the given input and return the
// computed hash
hash_bytes :: proc(data: []byte) -> [DIGEST_SIZE]byte {
	hash: [DIGEST_SIZE]byte
	ctx: Context
	cfg: _blake2.Blake2_Config
	cfg.size = _blake2.BLAKE2B_SIZE
	ctx.cfg = cfg
	init(&ctx)
	update(&ctx, data)
	final(&ctx, hash[:])
	return hash
}

// hash_string_to_buffer will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer :: proc(data: string, hash: []byte) {
	hash_bytes_to_buffer(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer :: proc(data, hash: []byte) {
	ctx: Context
	cfg: _blake2.Blake2_Config
	cfg.size = _blake2.BLAKE2B_SIZE
	ctx.cfg = cfg
	init(&ctx)
	update(&ctx, data)
	final(&ctx, hash)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([DIGEST_SIZE]byte, bool) {
	hash: [DIGEST_SIZE]byte
	ctx: Context
	cfg: _blake2.Blake2_Config
	cfg.size = _blake2.BLAKE2B_SIZE
	ctx.cfg = cfg
	init(&ctx)

	buf := make([]byte, 512)
	defer delete(buf)

	read := 1
	for read > 0 {
		read, _ = io.read(s, buf)
		if read > 0 {
			update(&ctx, buf[:read])
		}
	}
	final(&ctx, hash[:])
	return hash, true
}

// hash_file will read the file provided by the given handle
// and compute a hash
hash_file :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE]byte, bool) {
	if !load_at_once {
		return hash_stream(os.stream_from_handle(hd))
	} else {
		if buf, ok := os.read_entire_file(hd); ok {
			return hash_bytes(buf[:]), ok
		}
	}
	return [DIGEST_SIZE]byte{}, false
}

hash :: proc {
	hash_stream,
	hash_file,
	hash_bytes,
	hash_string,
	hash_bytes_to_buffer,
	hash_string_to_buffer,
}

/*
    Low level API
*/

Context :: _blake2.Blake2b_Context

init :: proc(ctx: ^Context) {
	_blake2.init(ctx)
}

update :: proc(ctx: ^Context, data: []byte) {
	_blake2.update(ctx, data)
}

final :: proc(ctx: ^Context, hash: []byte) {
	_blake2.final(ctx, hash)
}
