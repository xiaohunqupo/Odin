#+build windows
package test_core_sys_windows

import "base:intrinsics"
import "core:testing"
import win32 "core:sys/windows"

UTF16_Vector :: struct {
	wstr: win32.wstring,
	ustr: string,
}

utf16_vectors := []UTF16_Vector{
	{
		"Hellope, World!",
		"Hellope, World!",
	},
	{
		"Hellope\x00, World!",
		"Hellope",
	},
}

@(test)
utf16_to_utf8_buf_test :: proc(t: ^testing.T) {
	for test in utf16_vectors {
		buf := make([]u8, len(test.ustr))
		defer delete(buf)

		wstr := string16(test.wstr)
		res := win32.utf16_to_utf8_buf(buf[:], transmute([]u16)wstr)
		testing.expect_value(t, res, test.ustr)
	}
}

@(test)
utf8_to_utf16_buf_test :: proc(t: ^testing.T) {
	buf : [100]u16 = ---
	// Test everything with a dirty buffer!
	reset_buffer :: proc(buf : []u16) {
		for i in 0 ..< len(buf) {
			buf[i] = cast(u16)(i + 1)
		}
	}

	result : []u16

	reset_buffer(buf[:])
	result = win32.utf8_to_utf16_buf(buf[:], "Hello\x00, World!")
	testing.expect_value(t, len(result), 14)
	testing.expect_value(t, result[4], 'o')
	testing.expect_value(t, result[5], 0)
	testing.expect_value(t, result[6], ',')
	testing.expect_value(t, result[13], '!')

	reset_buffer(buf[:])
	result = win32.utf8_to_utf16_buf(buf[:], "H\x00\x00")
	testing.expect_value(t, len(result), 3)
	testing.expect_value(t, result[1], 0)
	testing.expect_value(t, result[2], 0)

	reset_buffer(buf[:])
	result = win32.utf8_to_utf16_buf(buf[:], "你好，世界！")
	testing.expect_value(t, len(result), 6)
	testing.expect_value(t, result[0], 0x4F60)
	testing.expect_value(t, result[1], 0x597D)
	testing.expect_value(t, result[2], 0xFF0C)
	testing.expect_value(t, result[3], 0x4E16)
	testing.expect_value(t, result[4], 0x754C)
	testing.expect_value(t, result[5], 0xFF01)

	reset_buffer(buf[:])
	result = win32.utf8_to_utf16_buf(buf[:4], "Hello")
	// Buffer too short.
	testing.expect(t, result == nil)

	reset_buffer(buf[:])
	result = win32.utf8_to_utf16_buf(buf[:], "")
	// Valid, but indistinguishable from an error.
	testing.expect_value(t, len(result), 0)

	reset_buffer(buf[:])
	result = win32.utf8_to_utf16_buf(buf[:0], "Hello")
	// Buffer too short.
	testing.expect(t, result == nil)
}

@(test)
utf8_to_wstring_buf_test :: proc(t : ^testing.T) {
	buf : [100]u16 = ---
	// Test everything with a dirty buffer!
	reset_buffer :: proc(buf : []u16) {
		for i in 0 ..< len(buf) {
			buf[i] = cast(u16)(i + 1)
		}
	}

	result : win32.wstring

	reset_buffer(buf[:])
	result = win32.utf8_to_wstring_buf(buf[:], "Hello\x00, World!")
	testing.expect(t, result != nil)
	testing.expect_value(t, buf[13], '!')
	testing.expect_value(t, buf[14], 0)

	reset_buffer(buf[:])
	result = win32.utf8_to_wstring_buf(buf[:], "H\x00\x00")
	testing.expect(t, result != nil)
	testing.expect_value(t, buf[1], 0)

	reset_buffer(buf[:])
	result = win32.utf8_to_wstring_buf(buf[:], "你好，世界！")
	testing.expect(t, result != nil)
	testing.expect_value(t, buf[0], 0x4F60)
	testing.expect_value(t, buf[1], 0x597D)
	testing.expect_value(t, buf[2], 0xFF0C)
	testing.expect_value(t, buf[3], 0x4E16)
	testing.expect_value(t, buf[4], 0x754C)
	testing.expect_value(t, buf[5], 0xFF01)
	testing.expect_value(t, buf[6], 0)

	reset_buffer(buf[:])
	result = win32.utf8_to_wstring_buf(buf[:5], "Hello")
	// Buffer too short.
	testing.expect_value(t, result, nil)

	reset_buffer(buf[:])
	result = win32.utf8_to_wstring_buf(buf[:6], "Hello")
	// Buffer *just* long enough.
	testing.expect(t, result != nil)
	testing.expect_value(t, buf[4], 'o')
	testing.expect_value(t, buf[5], 0)

	reset_buffer(buf[:])
	result = win32.utf8_to_wstring_buf(buf[:], "")
	// Valid, and distinguishable from an error.
	testing.expect(t, result != nil)
	testing.expect_value(t, buf[0], 0)

	reset_buffer(buf[:])
	result = win32.utf8_to_wstring_buf(buf[:0], "Hello")
	// Buffer too short.
	testing.expect(t, result == nil)
}
