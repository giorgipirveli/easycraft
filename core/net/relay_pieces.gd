class_name RelayPieces
extends RefCounted
## Big multiplayer packets cut into pieces for the Nakama relay, and put back together (M4 early
## spike). Nakama closes a session that sends a message over socket.max_message_size_bytes, and the
## host's voxel sync sends the whole world around a joining guest as one packet (537 KB measured,
## docs/devlog/parts/m4-online-spike.md). Each piece is [total size u32][offset u32][bytes], little
## endian. One sender's pieces arrive in order (one socket; Nakama relays a sender's messages in
## order), so a piece that does not continue its packet means one went missing: that packet is
## dropped, never delivered with a hole.

const PIECE_BYTES := 32 * 1024     # about 44 KB once the client wraps it in base64 and JSON
const HEADER_BYTES := 8
const MAX_PACKET_BYTES := 1 << 24  # NakamaMultiplayerPeer.MAX_PACKET_SIZE


static func split(packet: PackedByteArray, piece_bytes: int = PIECE_BYTES) -> Array[PackedByteArray]:
	var out: Array[PackedByteArray] = []
	var offset := 0
	while offset < packet.size():
		var n := mini(piece_bytes, packet.size() - offset)
		var piece := PackedByteArray()
		piece.resize(HEADER_BYTES)
		piece.encode_u32(0, packet.size())
		piece.encode_u32(4, offset)
		piece.append_array(packet.slice(offset, offset + n))
		out.append(piece)
		offset += n
	return out


## Puts each sender's pieces back together.
class Assembler:
	extends RefCounted

	var _partial := {}   # sender -> {"size": int, "have": int, "parts": Array[PackedByteArray]}

	## The whole packet once `piece` completes it, else an empty array.
	func add(sender: String, piece: PackedByteArray) -> PackedByteArray:
		if piece.size() <= HEADER_BYTES:
			return PackedByteArray()
		var size := piece.decode_u32(0)
		var offset := piece.decode_u32(4)
		if size == 0 or size > MAX_PACKET_BYTES:
			_partial.erase(sender)
			return PackedByteArray()
		if offset == 0:
			_partial[sender] = {"size": size, "have": 0, "parts": []}
		var entry: Dictionary = _partial.get(sender, {})
		if entry.is_empty() or int(entry.size) != size or int(entry.have) != offset:
			_partial.erase(sender)   # a piece went missing
			return PackedByteArray()
		var bytes := piece.slice(HEADER_BYTES)
		entry.have = int(entry.have) + bytes.size()
		(entry.parts as Array).append(bytes)
		if int(entry.have) < size:
			return PackedByteArray()
		_partial.erase(sender)
		if int(entry.have) > size:
			return PackedByteArray()
		var whole := PackedByteArray()
		for part: PackedByteArray in entry.parts:
			whole.append_array(part)
		return whole

	func forget(sender: String) -> void:
		_partial.erase(sender)
