#!/usr/bin/env bash

set -e

backgrounds_dir="./backgrounds"
system_bg_dir="${backgrounds_dir}/system/usr/share/backgrounds"
system_bg_properties_dir="$(dirname "$system_bg_dir")/gnome-background-properties"
outpur_file="./backgrounds.7z"

if ! [[ -d "$system_bg_dir" ]]; then
	echo "Error: $system_bg_dir directory does not exist"
	exit 1
fi

[[ -d "$system_bg_properties_dir" ]] || mkdir -p "$system_bg_properties_dir"

get_timed_xml() {
	local name=$1
	local light_ext=$2
	local dark_ext=$3

	cat <<EOF
<background>
    <starttime>
        <year>2024</year>
        <month>07</month>
        <day>10</day>
        <hour>7</hour>
        <minute>00</minute>
        <second>00</second>
    </starttime>

    <!-- This animation will start at 7 AM. -->

    <!-- We start with sunrise at 7 AM. It will remain up for 1 hour. -->
    <static>
        <duration>3600.0</duration>
        <file>/usr/share/backgrounds/${name}/${name}-Light.${light_ext}</file>
    </static>

    <!-- Sunrise starts to transition to day at 8 AM. The transition lasts for 5 hours, ending at 1 PM. -->
    <transition type="overlay">
        <duration>18000.0</duration>
        <from>/usr/share/backgrounds/${name}/${name}-Light.${light_ext}</from>
        <to>/usr/share/backgrounds/${name}/${name}-Light.${light_ext}</to>
    </transition>

    <!-- It's 1 PM, we're showing the day image in full force now, for 5 hours ending at 6 PM. -->
    <static>
        <duration>18000.0</duration>
        <file>/usr/share/backgrounds/${name}/${name}-Light.${light_ext}</file>
    </static>

    <!-- It's 6 PM and it's going to start to get darker. This will transition for 1 hour until 7 PM. -->
    <transition type="overlay">
        <duration>3600.0</duration>
        <from>/usr/share/backgrounds/${name}/${name}-Light.${light_ext}</from>
        <to>/usr/share/backgrounds/${name}/${name}-Dark.${dark_ext}</to>
    </transition>

    <!-- It's 7 PM. It'll stay dark for 10 hours up until 5 AM. -->
    <static>
        <duration>36000.0</duration>
        <file>/usr/share/backgrounds/${name}/${name}-Dark.${dark_ext}</file>
    </static>

    <!-- It's 5 AM. We'll start transitioning to sunrise for 2 hours up until 7 AM. -->
    <transition type="overlay">
        <duration>7200.0</duration>
        <from>/usr/share/backgrounds/${name}/${name}-Dark.${dark_ext}</from>
        <to>/usr/share/backgrounds/${name}/${name}-Light.${light_ext}</to>
    </transition>
</background>
EOF
}

get_background_properties() {
	local name=$1
	local light_ext=$2
	local dark_ext=$3
	local primary_color=$4
	local secondary_color=$5

	cat <<EOF
<?xml version="1.0"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false">
    <name>${name} Background</name>
    <filename>/usr/share/backgrounds/${name}/${name}-Light.${light_ext}</filename>
    <filename-dark>
      /usr/share/backgrounds/${name}/${name}-Dark.${dark_ext}</filename-dark>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>${primary_color}</pcolor>
    <scolor>${secondary_color}</scolor>
  </wallpaper>

  <wallpaper deleted="false">
    <name>${name} Time of Day</name>
    <filename>/usr/share/backgrounds/${name}/${name}-timed.xml</filename>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>${primary_color}</pcolor>
    <scolor>${secondary_color}</scolor>
  </wallpaper>
</wallpapers>
EOF
}

build_dynamic_backgrounds() {
	for dir in "${system_bg_dir}"/*; do
		if [[ -d $dir ]]; then
			local background_name light_file dark_file light_ext dark_ext timed_xml_file background_property_file

			background_name=$(basename "$dir")
			light_file=$(find "$dir" -name "*-Light.*" | head -n 1)
			dark_file=$(find "$dir" -name "*-Dark.*" | head -n 1)
			light_ext="${light_file##*.}"
			dark_ext="${dark_file##*.}"
			timed_xml_file="${system_bg_dir}/${background_name}/${background_name}-timed.xml"
			background_property_file="${system_bg_properties_dir}/${background_name}.xml"

			[[ -f "${timed_xml_file}" || -f "${background_property_file}" ]] && continue

			if [[ -z "$light_file" || -z "$dark_file" ]]; then
				echo "Warning: Missing Light or Dark file for background $background_name"
				echo "Skipping..."
				continue
			fi

			get_timed_xml "$background_name" "$light_ext" "$dark_ext" >"$timed_xml_file"
			get_background_properties "$background_name" "$light_ext" "$dark_ext" "#000000" "#000000" >"$background_property_file"
		fi
	done
}

compress() {
	7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on "$outpur_file" "$backgrounds_dir"
}

build() {
	build_dynamic_backgrounds
	compress
}

if build; then
	echo "Build completed successfully!"
else
	echo "Error during build!"
fi
