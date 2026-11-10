extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/art_catalog.json"))
	var manifest:Dictionary={}
	var directory:="res://assets/art/thumbnails"
	DirAccess.make_dir_recursive_absolute(directory)
	var count:=0
	for entry in catalog.works:
		var path:String=entry.asset_path
		if not ResourceLoader.exists(path): continue
		var texture:Texture2D=load(path)
		var picture:=texture.get_image()
		if picture.is_compressed(): picture.decompress()
		var fit:=minf(46.0/picture.get_width(),34.0/picture.get_height())
		picture.resize(maxi(4,int(picture.get_width()*fit)),maxi(4,int(picture.get_height()*fit)),Image.INTERPOLATE_LANCZOS)
		var target:String=directory+"/"+str(entry.id)+".png"
		var error:=picture.save_png(target)
		if error != OK:
			push_error("Cannot save thumbnail: "+target)
			quit(1)
			return
		manifest[entry.id]={"source":path,"source_sha256":FileAccess.get_sha256(path),"thumbnail":target,"width":picture.get_width(),"height":picture.get_height()}
		count+=1
	var file=FileAccess.open(directory+"/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"))
	file.close()
	print("ART_THUMBNAILS_BUILT: ",count)
	quit()
