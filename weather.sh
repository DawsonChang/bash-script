#set the default variables
loc="Taipei"
type="temp_c"
wind="wind_kph"
feel="feelslike_c"
vis="vis_km"
unit="℃"
unit_2="kph"
unit_3="km"

#if exists environment variable APIXUKEY, use it. else use default variable(-z means following variable does not exist)
if [[ -z "$APIXUKEY" ]]
then
	APIXUKEY="4a23dfec38ef4abe9e7170847181511"
fi

#check what options are given
while getopts ":fl:u" opt
do
	case $opt in
	#show the data with Fahrenheit degrees
	f)
		type="temp_f"
		wind="wind_mph"
		feel="feelslike_f"
		vis="vis_miles"
		unit="℉"
		unit_2="mph"
		unit_3="mile"
		;;
	#the argument should be used as new location
	l)
		loc="$OPTARG"
		;;
	#update the data in every 5 minutes
	u)
		rec="TRUE"
		;;
	#if use argument different from above, show this error
	\?)
		VAR_D="$OPTARG"
		echo "Invalid option: -$VAR_D"
		exit 1
		;;
	#if any argument needs following argument but don't get it, show this error
	:)
		echo "Option -$OPTARG requires an argument."
		exit 1
		;;

	esac
done

while [ : ]
do
	#get data from website and use 'sed' to access the information what we want
	#get temperture
	r1="$(curl -s "http://api.apixu.com/v1/current.xml?key=${APIXUKEY}&q=${loc}" | sed 's/></\n/g' | \
	grep -n ''"$type"'' | sed 's/^.*'"$type"'>//g' | sed 's/<\/.*$//g')"
	
	#get weather condition
	text="$(curl -s "http://api.apixu.com/v1/current.xml?key=${APIXUKEY}&q=${loc}" | sed 's/></\n/g' | \
	grep -n 'text' | sed 's/^.*text>//g' | sed 's/<\/.*$//g')"

	#get wind speed
	r3="$(curl -s "http://api.apixu.com/v1/current.xml?key=${APIXUKEY}&q=${loc}" | sed 's/></\n/g' | \
	grep -n ''"$wind"'' | sed 's/^.*'"$wind"'>//g' | sed 's/<\/.*$//g')"
	
	#get feeling temperture
	r4="$(curl -s "http://api.apixu.com/v1/current.xml?key=${APIXUKEY}&q=${loc}" | sed 's/></\n/g' | \
	grep -n ''"$feel"'' | sed 's/^.*'"$feel"'>//g' | sed 's/<\/.*$//g')"
	
	#get visibility
	r5="$(curl -s "http://api.apixu.com/v1/current.xml?key=${APIXUKEY}&q=${loc}" | sed 's/></\n/g' | \
	grep -n ''"$vis"'' | sed 's/^.*'"$vis"'>//g' | sed 's/<\/.*$//g')"
	
	#get uv
	uv="$(curl -s "http://api.apixu.com/v1/current.xml?key=${APIXUKEY}&q=${loc}" | sed 's/></\n/g' | \
	grep -n 'uv' | sed 's/^.*uv>//g' | sed 's/<\/.*$//g')"
	
	#check whether the downloaded data exist or not(-f argument: if file exist, it will return TRUE)
	if [ -f /tmp/weather_data.txt ]
	then
		#if file exist, check the previous time at the first line of txt file
		previous_time="`sed -n 1p /tmp/weather_data.txt`"
		#get the current time 
		current_time=$(date "+%s")
	else
		#if file does not exist, set time to zero for the next if statement
		previous_time=0
		current_time=0
	fi

#if lasting time is greater than 300 seconds(5 mintues) or the file does not exist, update the data
if [[ $(( $current_time - $previous_time )) -gt 300 ]] || [ ! -f /tmp/weather_data.txt ]
then

	#update the time & overwrite/create the file
	#the first line use '>' because we have to clean the previous file and input new data in it
	date "+%s" > /tmp/weather_data.txt
	
	#the line below use '>>' because we just want to add new line in existing file
	echo $loc >> /tmp/weather_data.txt
	echo $r1 >> /tmp/weather_data.txt
	echo $text >> /tmp/weather_data.txt
	echo $r3 >> /tmp/weather_data.txt
	echo $r4 >> /tmp/weather_data.txt
	echo $r5 >> /tmp/weather_data.txt
	echo $uv >> /tmp/weather_data.txt

fi
	#clear the screen
	clear
	
	#print ASCII-art style 'weather'
	tput cup 2 14
	echo -e "\e[42m\e[30m	                    _   _               "
	tput cup 3 14
	echo -e "	__      _____  __ _| |_| |__   ___ _ __ "
	tput cup 4 14
	echo -e "	\ \ /\ / / _ \/ _\` | __| '_ \ / _ \ '__|"
	tput cup 5 14
	echo -e "	 \ V  V /  __/ (_| | |_| | | |  __/ |   "
	tput cup 6 14
	echo -e "	  \_/\_/ \___|\__,_|\__|_| |_|\___|_|   \e[39m\e[49m"
	
	
	tput cup 8 20
	echo -e "\e[93m$loc\e[39m"
	tput cup 9 20

	echo -e "current temperture($unit): \c"
	echo -e "\e[47m\e[31m$r1$unit\e[39m\e[49m"
	
	tput cup 10 20

	echo -e "weather condition: \c"
	echo -e "\e[47m\e[31m$text\e[39m\e[49m"

	tput cup 11 20

	echo -e "wind speed($unit_2): \c"
	echo -e "\e[47m\e[31m$r3$unit_2\e[39m\e[49m"

	tput cup 12 20

	echo -e "feeling temperture($unit): \c"
	echo -e "\e[47m\e[31m$r4$unit\e[39m\e[49m"

	tput cup 13 20

	echo -e "visibility($unit_3): \c"
	echo -e "\e[47m\e[31m$r5$unit_3\e[39m\e[49m"

	tput cup 14 20

	echo -e "UV Index: \c"
	echo -e "\e[47m\e[31m$uv\e[39m\e[49m"
	
	#if use argument -u, update the result every 5 minutes
	if [[ $rec == 'TRUE' ]]
	then
		sleep 300
	#if not use -u, exit the script
	else
		exit 0
	fi
	
done
