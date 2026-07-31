Base64 := [].{
	encode : List(U8) -> Str
	encode = |bytes|
		Str.from_utf8_lossy(encode_help(bytes, []))
}

alphabet : List(U8)
alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".to_utf8()

alphabet_byte : U8 -> U8
alphabet_byte = |index| alphabet.get(index.to_u64()) ?? 65

encode_help : List(U8), List(U8) -> List(U8)
encode_help = |remaining, encoded|
	match remaining {
		[] => encoded
		[first] =>
			encoded
				.append(alphabet_byte(first // 4))
				.append(alphabet_byte((first % 4) * 16))
				.append(61)
				.append(61)
		[first, second] =>
			encoded
				.append(alphabet_byte(first // 4))
				.append(alphabet_byte((first % 4) * 16 + second // 16))
				.append(alphabet_byte((second % 16) * 4))
				.append(61)
		[first, second, third, .. as rest] =>
			encode_help(
				rest,
				encoded
					.append(alphabet_byte(first // 4))
					.append(alphabet_byte((first % 4) * 16 + second // 16))
					.append(alphabet_byte((second % 16) * 4 + third // 64))
					.append(alphabet_byte(third % 64)),
			)
		}

expect Base64.encode([]) == ""
expect Base64.encode("f".to_utf8()) == "Zg=="
expect Base64.encode("fo".to_utf8()) == "Zm8="
expect Base64.encode("foo".to_utf8()) == "Zm9v"
expect Base64.encode("business card".to_utf8()) == "YnVzaW5lc3MgY2FyZA=="
