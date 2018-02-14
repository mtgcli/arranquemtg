#!/usr/local/bin/ruby
#<Encoding:UTF-8>

require 'open-uri'
require 'json'
require 'zlib'


module INICIO
	class Inicio
		def arranque
			Dir.chdir(Dir.home)
			puts Dir.pwd
			dir = File.join("rubymtg")
			@dirdb = File.join(dir,"dbmtg")
			
			# Función para descomprimir
			def descompr srcjson
				srcgz = File.join(@dirdb,"#{srcjson}.gz")
				jsondes = File.open("#{@dirdb}/#{srcjson}.json","w")
				Zlib::GzipReader.open(srcgz) do |gz|
					jsondes.write(gz.read)
					jsondes.close
				end
			end
			
			if !Dir.exist?(dir)
				Dir.mkdir(dir, 0700)
			end
			
## Verifica la existencia del archivo version.json si no existe lo descarga
			if !Dir.exist?(@dirdb)
				Dir.mkdir(@dirdb)
			  gitversion = open('https://raw.githubusercontent.com/MoiRouhs/dbmtg/master/mtgbase/version.json',{ read_timeout: 2 })
			  gitversion = JSON.parse(gitversion.read())
			  localversion = open("#{@dirdb}/version.json","w")
			  localversion.write(JSON.pretty_generate(gitversion))
			  localversion.close
			end
			db = ["AllCards-x","AllSets-x"]
			v_json = File.open("#{@dirdb}/version.json", "r")
			v_json = JSON.parse(v_json.read())
			cartas = File.join(@dirdb,db[0])
			sets = File.join(@dirdb,db[1])
## Verifica existencia de archivos de sets y cartas comprimidos, en caso de no existir los descarga	
			if !File.exist?(cartas+".gz") and !File.exist?(sets+".gz")
				db.each do |x|
					xj = "#{x}.json"
					scdir =File.join(@dirdb,xj)
					if !File.exist?(scdir)
						puts "Descargando #{x}"
						dbzip = open(v_json[x], { read_timeout: 2 })
						IO.copy_stream(dbzip,"#{@dirdb}/#{x}.gz")
					end
				end
			end 	
## Verifica existencia de los json y los gz  para descomprimirlos 	
			if !File.exist?(cartas+".json") and !File.exist?(sets+".json") and File.exist?(cartas+".gz") and File.exist?(sets+".gz")
				puts "descomprimiendo"
				a = Thread.new{
					descompr db[0]
				}
				b = Thread.new{
					descompr db[1]
				}
				a.join
				b.join
			end
		end
## Crea un json con ayuda para buscar según categorías como color, nombre, tipo
		def configuracion
			cpth = File.join(Dir.home,"rubymtg","dbmtg","AllCards-x.json")
			dbcards = File.open(cpth,"r")
			dbcards = JSON.parse(dbcards.read())
			config ={"name"=>[],"colors"=>[],"types"=>[],"subtypes"=>[]}
			categorias = config.keys
			dbcards.each_key do |k|
				categorias.each do |c|
					if dbcards[k][c].instance_of? Array
						for x in dbcards[k][c]
							 t = config[c] 
							if !t.include?(x)
								config[c] << x
							end
						end
					else
						if !config[c].include?(dbcards[k][c])
							config[c] << dbcards[k][c]
						end
					end 
				end
			end
			return config
		end
## Comprueba existencia del archivo option.json y en caso de no existir lo crea
		def existconfig
			confpath = File.join(Dir.home,"rubymtg","dbmtg","option.json")
			if !File.exist?(confpath)
				option = configuracion
				option_json = File.open(confpath,"w")
				option_json.write(JSON.pretty_generate(option))
				option_json.close
			end
		end
	end
end
