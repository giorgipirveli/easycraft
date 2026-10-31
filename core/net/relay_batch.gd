class_name RelayBatch
extends RefCounted
## Several small Godot packets in one relay message (M4 Wave 1 A). Every Nakama message carries a JSON
## envelope (match id, op code, often the target's presence) of about 300 bytes, several times a
## position update, so RelayBridge sends a run of packets for the same target as one message:
## [u16 size][packet] repeated, little endian. Packets are at most RelayPieces.PIECE_BYTES.


## The batch with one more packet (packed arrays are values: use what it returns).
static func add(batch: PackedByteArray, packet: PackedByteArray) -> PackedByteArray:
	var out := batch
	var at := out.size()
	out.resize(at + 2)
	out.encode_u16(at, packet.size())
	out.append_array(packet)
	return out


## The packets of a batch, in order; [] when it is malformed.
static func split(batch: PackedByteArray) -> Array[PackedByteArray]:
	var out: Array[PackedByteArray] = []
	var o := 0
	while o < batch.size():
		if o + 2 > batch.size():
			return []
		var n := batch.decode_u16(o)
		o += 2
		if o + n > batch.size():
			return []
		out.append(batch.slice(o, o + n))
		o += n
	return out
