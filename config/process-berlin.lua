-- Data processing based on openmaptiles.org schema
-- https://openmaptiles.org/schema/
-- Copyright (c) 2016, KlokanTech.com & OpenMapTiles contributors.
-- Used under CC-BY 4.0

-- Enter/exit Tilemaker
function init_function()
end
function exit_function()
end

-- Implement Sets in tables
function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

-- Meters per pixel if tile is 256x256
ZRES5  = 4891.97
ZRES6  = 2445.98
ZRES7  = 1222.99
ZRES8  = 611.5
ZRES9  = 305.7
ZRES10 = 152.9
ZRES11 = 76.4
ZRES12 = 38.2
ZRES13 = 19.1

-- The height of one floor, in meters
BUILDING_FLOOR_HEIGHT = 3.66

-- Process node/way tags
aerodromeValues = Set { "international", "public", "regional", "military", "private" }

function string.starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end


-- Process node tags
-- Needed to add highway for "bus_station"
node_keys = { "highway", "railway", "subway", "public_transport", "tourism", "place", "natural", "addr:housenumber", "aeroway" }
function node_function()
	-- local operator = Find("operator");
	-- local route = Find("route");
	-- local network = Find("network");
	-- local railway = Find("railway");

	-- if railway == "station" then
	-- 	print("Operator:", railway, operator, route, network)
	-- end
 
	local operator = Find("operator")
	local highway = Find("highway")
	local subway = Find("subway")
	local train = Find("train")
	local bus = Find("bus")
	local tram = Find("tram")
	local railway = Find("railway")
	local public_transport = Find("public_transport")
	local amenity = Find("amenity")
	local office = Find("office")
	local building = Find("building")
	local craft = Find("craft")
	

	if amenity == "ferry_terminal" then
		LayerAsCentroid("poi")
		SetNameAttributes(node)
		AttributeNumeric("rank", 3)
		Attribute("class", "ferry")
		return
	end

	if highway == "bus_stop" and public_transport ~= "stop_position" and bus ~= "yes" then
		LayerAsCentroid("poi")
		SetNameAttributes(node)
		AttributeNumeric("rank", 12)
		Attribute("class", "bus")
		return
	end

	-- https://wiki.openstreetmap.org/wiki/Public_transport
	if public_transport ~= "" then
		local name = Find("name")
		
		if public_transport == "entrance" or railway == "subway_entrance" then
			LayerAsCentroid("poi")
			SetNameAttributes(node)
			AttributeNumeric("rank", 25)
			Attribute("class", "entrance")
			return
		elseif public_transport == "station" then
		
			if subway == "yes" then
				LayerAsCentroid("poi")
				SetNameAttributes(node)
				AttributeNumeric("rank", 3)
				if name ~= "" and string.starts(name, "S ") then
					Attribute("class", "sbahn")
				else
					Attribute("class", "railway_metro")
				end
				return

			elseif train == "yes" or railway == "station" or railway == "halt" then 
				LayerAsCentroid("poi")
				if name ~= "" and string.starts(name, "S ") then
					LayerAsCentroid("poi")
					SetNameAttributes(node)
					AttributeNumeric("rank", 3)
					Attribute("class", "sbahn")
					return
				else
					
					SetNameAttributes(node)
					AttributeNumeric("rank", 3)
					Attribute("class", "railway")
					return
				end				
			else
				-- TODO: ist there anything else to treat? 
				print("ooops station:", public_transport, "HIGH", Find("highway"), "SUB", Find("subway"), "TRAIN", Find("train"), "BUS", Find("bus"), "TRAM", Find("tram"), 
				"RAILWAY", Find("railway"), Find("name"))
			end
			return
		elseif public_transport == "stop_position" then
			

			if bus == "yes" then
				
				LayerAsCentroid("poi")
				SetNameAttributes(node)
				AttributeNumeric("rank", 12)
				Attribute("class", "bus")
				return
			elseif tram == "yes" and railway == "tram_stop" then
				LayerAsCentroid("poi")
				SetNameAttributes(node)
				AttributeNumeric("rank", 12)
				Attribute("class", "railway_light")
				return
			else
				-- TODO: ist there anything else to treat? 
				-- print("ooops stop_position:", public_transport, "HIGH", Find("highway"), "SUB", Find("subway"), "TRAIN", Find("train"), "BUS", Find("bus"), "TRAM", Find("tram"), 
				-- "RAILWAY", Find("railway"), Find("name"))
			end
			
		else
			-- TODO: ist there anything else to treat? 
			-- if public_transport ~= "platform" then
			-- 	print("opps catcha all:", public_transport, "HIGH", Find("highway"), "SUB", Find("subway"), "TRAIN", Find("train"), "BUS", Find("bus"), "TRAM", Find("tram"), 
			-- "RAILWAY", Find("railway"), Find("name"))
			-- end
		end
		
	end

	-- Write 'aerodrome_label'
	local aeroway = Find("aeroway")
	if aeroway == "aerodrome" then
		Layer("aerodrome_label", false)
		SetNameAttributes(node)
		Attribute("iata", Find("iata"))
		SetEleAttributes(node)
		Attribute("icao", Find("icao"))

		local aerodrome_value = Find("aerodrome")
		local class
		if aerodromeValues[aerodrome_value] then class = aerodrome_value else class = "other" end
		Attribute("class", class)
	end

	-- Write 'housenumber'
	local housenumber = Find("addr:housenumber")
	if (housenumber~="" and building ~="") or (housenumber~="" and amenity=="" and shop=="" and office=="" and craft=="") then
		Layer("housenumber", false)
		Attribute("housenumber", housenumber)
	end
	
	-- Write 'place'
	-- note that OpenMapTiles has a rank for countries (1-3), states (1-6) and cities (1-10+);
	--   we could potentially approximate it for cities based on the population tag
	local place = Find("place")
	if place ~= "" then
		local rank = nil
		local mz = 13
		local pop = tonumber(Find("population")) or 0

		if     place == "continent"     then mz=0
		elseif place == "country"       then
			if     pop>50000000 then rank=1; mz=1
			elseif pop>20000000 then rank=2; mz=2
			else                     rank=3; mz=3 end
		elseif place == "state"         then mz=4
		elseif place == "city"          then mz=5
		elseif place == "town" and pop>8000 then mz=7
		elseif place == "town"          then mz=8
		elseif place == "village" and pop>2000 then mz=9
		elseif place == "village"       then mz=10
		elseif place == "suburb"        then mz=11
		elseif place == "hamlet"        then mz=12
		elseif place == "neighbourhood" then mz=13
		elseif place == "locality"      then mz=13
		end

		Layer("place", false)
		Attribute("class", place)
		MinZoom(mz)

		
		if rank then AttributeNumeric("rank", rank) end
		if place=="country" then Attribute("iso_a2", Find("ISO3166-1:alpha2")) end
		SetNameAttributes(node)
		return
	end

	

	-- Write 'poi'
	local rank, class, subclass = GetPOIRank(node)
	if rank then 
		WritePOI(node,class,subclass,rank)
	end

	-- Write 'mountain_peak' and 'water_name'
	local natural = Find("natural")
	if natural == "peak" or natural == "volcano" then
		Layer("mountain_peak", false)
		SetEleAttributes(node)
		AttributeNumeric("rank", 1)
		Attribute("class", natural)
		SetNameAttributes(node)
		return
	end
	if natural == "bay" then
		Layer("water_name", false)
		SetNameAttributes(node)
		return
	end
end

-- Process way tags

majorRoadValues = Set { "motorway", "trunk", "primary" }
mainRoadValues  = Set { "secondary", "motorway_link", "trunk_link", "primary_link", "secondary_link" }
midRoadValues   = Set { "tertiary", "tertiary_link" }
minorRoadValues = Set { "unclassified", "residential", "road", "living_street" }
trackValues     = Set { "cycleway", "byway", "bridleway", "track" }
pathValues      = Set { "footway", "path", "steps" }
linkValues      = Set { "motorway_link", "trunk_link", "primary_link", "secondary_link", "tertiary_link" }
constructionValues = Set { "primary", "secondary", "tertiary", "motorway", "service", "trunk", "track" }

aerowayBuildings= Set { "terminal", "gate", "tower" }
landuseKeys     = Set { "school", "university", "kindergarten", "college", "library", "hospital",
                        "railway", "cemetery", "military", "residential", "commercial", "industrial",
                        "retail", "stadium", "pitch", "playground", "theme_park", "bus_station", "zoo" }
landcoverKeys   = { wood="wood", forest="wood",
                    wetland="wetland",
                    beach="sand", sand="sand",
                    farmland="farmland", farm="farmland", orchard="farmland", vineyard="farmland", plant_nursery="farmland",
                    glacier="ice", ice_shelf="ice",
                    grassland="grass", grass="grass", meadow="grass", allotments="grass", park="grass", village_green="grass", recreation_ground="grass", garden="grass", golf_course="grass" }

poiTags = { 
	aerialway = Set { "station" },
	amenity = Set { "arts_centre", "bicycle_parking", "bicycle_rental", "bus_station", "college", "community_centre", "courthouse", "ferry_terminal", "fire_station",  "fuel", "grave_yard", "hospital", "library",  "place_of_worship", "police", "post_box", "public_building", "recycling", "school", "taxi", "telephone", "theatre", "toilets", "townhall", "university", "waste_basket" },
	barrier = Set { "bollard", "border_control", "cycle_barrier", "gate", "lift_gate", "sally_port", "stile", "toll_booth" },
	building = Set { "dormitory" },
	highway = Set { "bus_stop" },
	historic = Set { "monument", "castle", "ruins" },
	landuse = Set { "basin", "cemetery", "reservoir", "winter_sports" },
	leisure = Set { "dog_park", "garden", "golf_course", "hackerspace", "marina","park","playground" },
	railway = Set { "halt", "station", "subway_entrance", "train_station_entrance", "tram_stop" },
	tourism = Set { "alpine_hut", "aquarium", "artwork", "attraction", "bed_and_breakfast", "camp_site", "caravan_site", "chalet", "gallery", "guest_house", "hostel", "hotel", "information", "motel", "museum", "picnic_site", "theme_park", "viewpoint", "zoo" },
	waterway = Set { "dock" }
}

-- POI "class" values: based on https://github.com/openmaptiles/openmaptiles/blob/master/layers/poi/poi.yaml
poiClasses      = { 
					townhall="town_hall", public_building="town_hall", courthouse="town_hall", community_centre="town_hall",
					golf="golf", golf_course="golf", miniature_golf="golf",
					fast_food="fast_food", food_court="fast_food",
					park="park", bbq="park",
					bus_stop="bus", bus_station="bus",
					subway_entrance="entrance", train_station_entrance="entrance",
					camp_site="campsite", caravan_site="campsite",
					laundry="laundry", dry_cleaning="laundry",
					supermarket="grocery", deli="grocery", delicatessen="grocery", department_store="grocery", greengrocer="grocery", marketplace="grocery",
					books="library", library="library",
					university="college", college="college",
					hotel="lodging", motel="lodging", bed_and_breakfast="lodging", guest_house="lodging", hostel="lodging", chalet="lodging", alpine_hut="lodging", dormitory="lodging",
					chocolate="ice_cream", confectionery="ice_cream",
					post_box="post",  post_office="post",
					cafe="cafe",
					school="school",  kindergarten="school",
					bar="bar", nightclub="bar",
					marina="harbor", dock="harbor",
					car="car", car_repair="car", taxi="car",
					hospital="hospital", nursing_home="hospital",  clinic="hospital",
					grave_yard="cemetery", cemetery="cemetery",
					attraction="attraction", viewpoint="attraction",
					biergarten="beer", pub="beer",
					music="music", musical_instrument="music",
					american_football="stadium", stadium="stadium", soccer="stadium",
					art="art_gallery", artwork="art_gallery", gallery="art_gallery", arts_centre="art_gallery",
					bag="clothing_store", clothes="clothing_store",
					swimming_area="swimming", swimming="swimming",
					castle="castle", ruins="castle",
					-- station="rail_metro",
					-- tram_stop="railway_light",
					-- halt="bus"

					station="railway", halt="railway",
					subway="railway_metro",
					tram_stop="railway_light",

					toilets="toilet",

				}
poiClassRanks   = { hospital=1, railway=2, bus=3, attraction=4, harbor=5, college=6,
					school=7, stadium=8, zoo=9, town_hall=10, campsite=11, cemetery=12,
					park=13, library=14, police=15, post=16 }
poiKeys         = Set { "amenity", "tourism", "historic", "landuse", "information" }
waterClasses    = Set { "river", "riverbank", "stream", "canal", "drain", "ditch", "dock" }
waterwayClasses = Set { "stream", "river", "canal", "drain", "ditch" }


function way_function()
	local route    = Find("route")
	local highway  = Find("highway")
	local waterway = Find("waterway")
	local water    = Find("water")
	local building = Find("building")
	local natural  = Find("natural")
	local historic = Find("historic")
	local landuse  = Find("landuse")
	local shop  	 = Find("shop")
	local leisure  = Find("leisure")
	local amenity  = Find("amenity")
	local aeroway  = Find("aeroway")
	local railway  = Find("railway")
	local service  = Find("service")
	local tourism  = Find("tourism")
	local man_made = Find("man_made")
	local boundary = Find("boundary")
	local isClosed = IsClosed()
	local housenumber = Find("addr:housenumber")
	local write_name = false
	local construction = Find("construction")

	-- -- https://wiki.openstreetmap.org/wiki/Public_transport
	-- if public_transport ~= "" then
	-- 	print("public_transport:", public_transport, "HIGH", Find("highway"), "SUB", Find("subway"), "TRAIN", Find("train"), "BUS", Find("bus"), "TRAM", Find("tram"), 
	-- 	"RAILWAY", Find("railway"), Find("name"))
	-- end

	-- Miscellaneous preprocessing
	if Find("disused") == "yes" then return end
	if boundary~="" and Find("protection_title")=="National Forest" and Find("operator")=="United States Forest Service" then return end
	if highway == "proposed" then return end
	if aerowayBuildings[aeroway] then building="yes"; aeroway="" end
	if landuse == "field" then landuse = "farmland" end
	if landuse == "meadow" and Find("meadow")=="agricultural" then landuse="farmland" end

	-- Boundaries
	if boundary~="" then
		local admin_level = tonumber(Find("admin_level")) or 11
		local mz = 0
		if     admin_level>=3 and admin_level<5 then mz=4
		elseif admin_level>=5 and admin_level<7 then mz=8
		elseif admin_level==7 then mz=10
		elseif admin_level>=8 then mz=12
		end
		if boundary~="" and Find("disputed")=="yes" then
			-- disputed boundaries
			Layer("boundary",false)
			AttributeNumeric("disputed", 1)
		elseif boundary=="administrative" and not (Find("maritime")=="yes") then
			-- administrative boundaries
			Layer("boundary",false)
			AttributeNumeric("admin_level", admin_level)
			MinZoom(mz)
		end
	end

	-- Roads ('transportation' and 'transportation_name', plus 'transportation_name_detail')
	if highway~="" then
		local access = Find("access")
		if access=="private" or access=="no" then return end

		local h = highway
		local minzoom = 99
		local layer = "transportation"
		if majorRoadValues[highway] then              minzoom = 4 end
		if highway == "trunk"       then              minzoom = 5
		elseif highway == "primary" then              minzoom = 7 end
		if mainRoadValues[highway]  then              minzoom = 9 end
		if midRoadValues[highway]   then              minzoom = 11 end
		if minorRoadValues[highway] then h = "minor"; minzoom = 12 end
		if trackValues[highway]     then h = "track"; minzoom = 14 end
		if pathValues[highway]      then h = "path" ; minzoom = 14 end
		if h=="service"             then              minzoom = 12 end

		-- Links (ramp)
		local ramp=false
		if linkValues[highway] then
			splitHighway = split(highway, "_")
			highway = splitHighway[1]; h = highway
			ramp = true
			minzoom = 11
		end

		-- Construction
		if highway == "construction" then
			if constructionValues[construction] then
				h = construction .. "_construction"
				if construction ~= "service" and construction ~= "track" then
					minzoom = 11
				else
					minzoom = 12
				end
			else
				h = "minor_construction"
				minzoom = 14
			end
		end

		-- Write to layer
		if minzoom <= 14 then
			Layer(layer, false)
			MinZoom(minzoom)
			-- SetZOrder(way)
			Attribute("class", h)
			SetBrunnelAttributes(way)
			if ramp then AttributeNumeric("ramp",1) end

			-- Service
			if highway == "service" and service ~="" then Attribute("service", service) end

			local oneway = Find("oneway")
			if oneway == "yes" or oneway == "1" then
				AttributeNumeric("oneway",1)
			end
			if oneway == "-1" then
				-- **** TODO
			end

			-- Write names
			if minzoom < 8 then
				minzoom = 8
			end
			if highway == "motorway" or highway == "trunk" then
				Layer("transportation_name", false)
				MinZoom(minzoom)
			elseif h == "minor" or h == "track" or h == "path" or h == "service" then
				Layer("transportation_name_detail", false)
				MinZoom(minzoom)
			else
				Layer("transportation_name_mid", false)
				MinZoom(minzoom)
			end
			SetNameAttributes(way)
			Attribute("class",h)
			Attribute("network","road") -- **** could also be us-interstate, us-highway, us-state
			if h~=highway then Attribute("subclass",highway) end
			local ref = Find("ref")
			if ref~="" then
				Attribute("ref",ref)
				AttributeNumeric("ref_length",ref:len())
			end
		end
	end

	-- Railways ('transportation' and 'transportation_name', plus 'transportation_name_detail')
	if railway~="" then
		Layer("transportation", false)
		Attribute("class", railway)
		SetBrunnelAttributes(way)
		if service~="" then
			Attribute("service", service)
			MinZoom(12)
		else
			MinZoom(9)
		end

		Layer("transportation_name", false)
		SetNameAttributes(way)
		MinZoom(14)
		Attribute("class", "rail")
	end

	if railway == "halt" or railway == "station" then
		print("SHOW RAILWAY STATION")
	end

	-- Pier
	if man_made=="pier" then
		Layer("transportation", isClosed)
		Attribute("class", "pier")
		SetMinZoomByArea(way)
	end

	-- 'Ferry'
	if route=="ferry" then
		Layer("transportation", false)
		Attribute("class", "ferry")
		MinZoom(9)
		SetBrunnelAttributes(way)

		Layer("transportation_name", false)
		SetNameAttributes(way)
		MinZoom(12)
		Attribute("class", "ferry")
	end

	-- 'Aeroway'
	if aeroway~="" then
		Layer("aeroway", isClosed)
		Attribute("class",aeroway)
		Attribute("ref",Find("ref"))
		write_name = true
	end

	-- 'aerodrome_label'
	if aeroway=="aerodrome" then
	 	LayerAsCentroid("aerodrome_label")
	 	SetNameAttributes(way)
	 	Attribute("iata", Find("iata"))
  	
		SetEleAttributes(way)
 	 	Attribute("icao", Find("icao"))

 	 	local aerodrome = Find(aeroway)
 	 	local class
 	 	if aerodromeValues[aerodrome] then class = aerodrome else class = "other" end
 	 	Attribute("class", class)
	end


	-- Set 'waterway' and associated
	if waterwayClasses[waterway] and not isClosed then
		if waterway == "river" and Holds("name") then
			Layer("waterway", false)
		else
			Layer("waterway_detail", false)
		end
		if Find("intermittent")=="yes" then AttributeNumeric("intermittent", 1) else AttributeNumeric("intermittent", 0) end
		Attribute("class", waterway)
		SetNameAttributes(way)
		SetBrunnelAttributes(way)
	elseif waterway == "boatyard"  then Layer("landuse", isClosed); Attribute("class", "industrial"); MinZoom(12)
	elseif waterway == "dam"       then Layer("building",isClosed)
	elseif waterway == "fuel"      then Layer("landuse", isClosed); Attribute("class", "industrial"); MinZoom(14)
	end
	-- Set names on rivers
	if waterwayClasses[waterway] and not isClosed then
		if waterway == "river" and Holds("name") then
			Layer("water_name", false)
		else
			Layer("water_name_detail", false)
			MinZoom(14)
		end
		Attribute("class", waterway)
		SetNameAttributes(way)
	end

	-- Set 'building' and associated
	if building~="" then
		Layer("building", true)
		SetBuildingHeightAttributes(way)
		SetMinZoomByArea(way)
	end

	-- Set 'housenumber'
	if housenumber~="" then
		LayerAsCentroid("housenumber")
		Attribute("housenumber", housenumber)
	end


	
	
	-- Set 'water'
	if natural=="water" or natural=="bay" or leisure=="swimming_pool" or landuse=="reservoir" or landuse=="basin" or waterClasses[waterway] then
		if Find("covered")=="yes" or not isClosed then return end
		local class="lake"; 
		
		if natural=="bay" then class="ocean" elseif waterway~="" then class="river" elseif landuse=="reservoir" or landuse=="basin" then class="other" end
		if class=="lake" and Find("wikidata")=="Q192770" then return end
		if class=="ocean" and isClosed and (AreaIntersecting("ocean")/Area() > 0.98) then return end
		Layer("water",true)
		SetMinZoomByArea(way)
		Attribute("class",class)
		if Find("intermittent")=="yes" then Attribute("intermittent",1) end
		-- we only want to show the names of actual lakes not every man-made basin that probably doesn't even have a name other than "basin"
		-- examples for which we don't want to show a name:
		--  https://www.openstreetmap.org/way/25958687
		--  https://www.openstreetmap.org/way/27201902
		--  https://www.openstreetmap.org/way/25309134
		--  https://www.openstreetmap.org/way/24579306

		if Holds("name") and natural=="water" and water ~= "basin" and water ~= "wastewater" then
			LayerAsCentroid("water_name_detail")
			SetNameAttributes(way)
			SetMinZoomByArea(way)
		end

		return -- in case we get any landuse processing
	end

	-- Set 'landcover' (from landuse, natural, leisure)
	local l = landuse
	if l=="" then l=natural end
	if l=="" then l=leisure end
	if landcoverKeys[l] then
		Layer("landcover", true)
		SetMinZoomByArea(way)
		Attribute("class", landcoverKeys[l])
		if l=="wetland" then Attribute("subclass", Find("wetland"))
		else Attribute("subclass", l) end
		write_name = true

	-- Set 'landuse'
	else
		if l=="" then l=amenity end
		if l=="" then l=tourism end
		if landuseKeys[l] then
			Layer("landuse", true)
			Attribute("class", l)
			if l=="residential" then
				if Area()<ZRES8^2 then MinZoom(8)
				else SetMinZoomByArea(way) end
			else MinZoom(11) end
			write_name = true
		end
	end

	-- Parks
	-- **** name?
	if     boundary=="national_park" then Layer("park",true); Attribute("class",boundary); SetNameAttributes(way)
	elseif leisure=="nature_reserve" then Layer("park",true); Attribute("class",leisure ); SetNameAttributes(way) end

	-- POIs ('poi' and 'poi_detail')
	local rank, class, subclass = GetPOIRank(way)
	if rank then 
		WritePOI(way,class,subclass,rank); 
	return end

	-- if Holds("shop") and Holds("name")  then 
	-- 	print("write shop", Find("name"))
	-- end

	-- Catch-all to add names
	-- filter for shops and restaurants

	if (building~="" or write_name) and Holds("name") and not Holds("shop") and amenity ~= "restaurant" and landuse ~= "commercial" and landuse ~= "industrial" and building ~= "retail" and building ~= "industrial" and building ~= "office" and building~="commercial" and building ~= "yes" then
		LayerAsCentroid("poi_detail")
		SetNameAttributes(way)
		if write_name then rank=6 else rank=25 end
		AttributeNumeric("rank", rank)
	end
end

-- Remap coastlines
function attribute_function(attr,layer)
	if attr["featurecla"]=="Glaciated areas" then
		return { subclass="glacier" }
	elseif attr["featurecla"]=="Antarctic Ice Shelf" then
		return { subclass="ice_shelf" }
	elseif attr["featurecla"]=="Urban area" then
		return { class="residential" }
	else
		return { class="ocean" }
	end
end

-- ==========================================================
-- Common functions

-- Write a way centroid to POI layer
function WritePOI(obj,class,subclass,rank)
	local layer = "poi"
	if rank>4 then layer="poi_detail" end
	LayerAsCentroid(layer)
	SetNameAttributes(obj)
	AttributeNumeric("rank", rank)
	Attribute("class", class)
	Attribute("subclass", subclass)
end

-- Set name, name_en, and name_de on any object
function SetNameAttributes(obj)
	Attribute("name", Find("name"))
	-- **** do transliteration
end

-- Set ele and ele_ft on any object
function SetEleAttributes(obj)
    local ele = Find("ele")
	if ele ~= "" then
		local meter = math.floor(tonumber(ele) or 0)
		local feet = math.floor(meter * 3.2808399)
		AttributeNumeric("ele", meter)
		AttributeNumeric("ele_ft", feet)
    end
end

function SetBrunnelAttributes(obj)
	if     Find("bridge") == "yes" then Attribute("brunnel", "bridge")
	elseif Find("tunnel") == "yes" then Attribute("brunnel", "tunnel")
	elseif Find("ford")   == "yes" then Attribute("brunnel", "ford")
	end
end

-- Set minimum zoom level by area
function SetMinZoomByArea(way)
	local area=Area()
	if     area>ZRES5^2  then MinZoom(6)
	elseif area>ZRES6^2  then MinZoom(7)
	elseif area>ZRES7^2  then MinZoom(8)
	elseif area>ZRES8^2  then MinZoom(9)
	elseif area>ZRES9^2  then MinZoom(10)
	elseif area>ZRES10^2 then MinZoom(11)
	elseif area>ZRES11^2 then MinZoom(12)
	elseif area>ZRES12^2 then MinZoom(13)
	else                      MinZoom(14) end
end

-- Calculate POIs (typically rank 1-4 go to 'poi' z12-14, rank 5+ to 'poi_detail' z14)
-- returns rank, class, subclass
function GetPOIRank(obj)
	local k,list,v,class,rank

	-- Catch-all for shops, make sure they never get a POI Rank
	local shop = Find("shop")
	if shop~="" then return nil, nil, nil end

	-- Can we find the tag?
	for k,list in pairs(poiTags) do
		if list[Find(k)] then
			v = Find(k)	-- k/v are the OSM tag pair
			class = poiClasses[v] or v
			rank  = poiClassRanks[class] or 25
			return rank, class, v
		end
	end

	-- Nothing found
	return nil,nil,nil
end

function SetBuildingHeightAttributes(way)
	local height = tonumber(Find("height"), 10)
	local minHeight = tonumber(Find("min_height"), 10)
	local levels = tonumber(Find("building:levels"), 10)
	local minLevel = tonumber(Find("building:min_level"), 10)

	local renderHeight = BUILDING_FLOOR_HEIGHT
	if height or levels then
		renderHeight = height or (levels * BUILDING_FLOOR_HEIGHT)
	end
	local renderMinHeight = 0
	if minHeight or minLevel then
		renderMinHeight = minHeight or (minLevel * BUILDING_FLOOR_HEIGHT)
	end

	-- Fix upside-down buildings
	if renderHeight < renderMinHeight then
		renderHeight = renderHeight + renderMinHeight
	end

	AttributeNumeric("render_height", renderHeight)
	AttributeNumeric("render_min_height", renderMinHeight)
end

-- ==========================================================
-- Lua utility functions

function split(inputstr, sep) -- https://stackoverflow.com/a/7615129/4288232
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

