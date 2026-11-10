extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/thumbnails/manifest.json"))
	var failures:Array[String]=[]
	var count:=0
	for id in manifest:
		var entry:Dictionary=manifest[id]
		if FileAccess.get_sha256(entry.source) != entry.source_sha256:
			failures.append("Source changed: "+id)
			continue
		var original:Texture2D=load(entry.source)
		var expected:=original.get_image()
		if expected.is_compressed(): expected.decompress()
		var fit:=minf(46.0/expected.get_width(),34.0/expected.get_height())
		expected.resize(maxi(4,int(expected.get_width()*fit)),maxi(4,int(expected.get_height()*fit)),Image.INTERPOLATE_LANCZOS)
		expected.convert(Image.FORMAT_RGBA8)
		var small:Texture2D=load(entry.thumbnail)
		var actual:=small.get_image()
		if actual.is_compressed(): actual.decompress()
		actual.convert(Image.FORMAT_RGBA8)
		if expected.get_size() != actual.get_size() or expected.get_data() != actual.get_data(): failures.append("Pixel mismatch: "+id)
		count+=1
	var frame=load("res://scripts/art_frame.gd").new()
	var first:Dictionary=manifest[manifest.keys()[0]]
	var full:Texture2D=load(first.source)
	frame.hang({"id":manifest.keys()[0]},full,"seeker")
	if frame.texture != full or frame.thumbnail == null or frame.branch != "seeker": failures.append("Frame must retain full-size image and gameplay branch")
	frame.free()
	for failure in failures: push_error(failure)
	print("ART_THUMBNAIL_RESULT: ",count," pixel-identical thumbnails; failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
