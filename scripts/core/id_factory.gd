class_name IdFactory
extends RefCounted

## Genera IDs opacos, no reutilizables en la práctica y sin depender de nombres
## visibles, modelos o posiciones. La secuencia de eventos es otro concepto.
static func new_id(prefix: String) -> String:
	var crypto := Crypto.new()
	var random_bytes: PackedByteArray = crypto.generate_random_bytes(16)
	if random_bytes.size() == 16:
		return "%s_%s" % [prefix, random_bytes.hex_encode()]

	# Fallback defensivo si el proveedor criptográfico del dispositivo falla.
	# No se utiliza como generador de semillas ni como fuente de tiempo del mundo.
	var fallback := "%d_%d_%d" % [Time.get_ticks_usec(), OS.get_process_id(), randi()]
	return "%s_%s" % [prefix, fallback.sha256_text().substr(0, 32)]
