#!/bin/bash

# Set up wego weather
brew install wego
wego
sed -i "s/^owm-api-key=.*/owm-api-key=$(bw get password c4f51d8a-7671-4006-9d7a-3785f32c06bc)/" ~/.wegorc
HOME_CITY="Herndon"
HOME_STATE="VA"
HOME_RESPONSE=$(curl -G https://nominatim.openstreetmap.org/search -d "city=${HOME_CITY}" -d "state=${HOME_STATE}" -d "format=json")
HOME_LAT=$(echo $HOME_RESPONSE | jq -r .[0].lat)
HOME_LON=$(echo $HOME_RESPONSE | jq -r .[0].lon)
sed -i "s/^location=.*/location=${HOME_LAT},${HOME_LON}/" ~/.wegorc
# Set up Pittsburgh Alias
#PITT_CITY="Pittsburgh"
#PITT_STATE="PA"
#PITT_RESPONSE=$(curl -G https://nominatim.openstreetmap.org/search -d "city=${HOME_CITY}" -d "state=${HOME_STATE}" -d "format=json")
#PITT_LAT=$(echo $PITT_RESPONSE | jq -r .[0].lat)
#PITT_LON=$(echo $PITT_RESPONSE | jq -r .[0].lon)
echo '' >> ~/.bashrc
echo '# WeGo aliases' >> ~/.bashrc
echo "alias wego-pitt='wego -location Pittsburgh'" >> ~/.bashrc
echo "alias wego-herndon='wego -location Herndon'" >> ~/.bashrc
